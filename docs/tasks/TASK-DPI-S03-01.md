# TASK-DPI-S03-01: vanguard_core.dart — Challenge Engine Headless

**Sprint**: S03-VANGUARD
**Label**: [SEC]
**CP**: 6
**Gate**: GATE-RED
**Revisor**: [GOV] PO (firma RSA obligatoria antes del baseline)
**Modelo**: Gemini Flash

## Contexto
Migrar la lógica de detección de challenges de `vanguard_agent/lib/main.dart` a Dart headless.
**Referencia Base2**: `Base2/vanguard_agent/lib/main.dart` — clases `ProjectUtils`, `_startWatcher`, `_loadChallenge`.
**Referencia Guard**: `Base2/ops-guard.ps1` líneas 34-140 — `Invoke-AsymmetricGuard`.

El Vanguard actual usa Flutter para la UI y `watcher` package para detectar `challenge.json`.
Esta tarea extrae SOLO la lógica (headless), sin UI. La notificación al PO será via CLI (`gov vault watch`).

## Scope:
- `lib/src/security/vanguard_core.dart`

## Interfaz a Implementar
```dart
class VanguardCore {
  // Vincula una clave privada XML a un ProjectId (anti-colisión entre proyectos)
  Future<BindResult> bindKey(String keyPath, String projectId);

  // Valida que la clave esté vinculada al proyecto correcto
  Future<ValidationResult> validateKey(String keyPath, String projectId);

  // Inicia el watcher de challenge.json — emite en el Stream cuando hay nuevo challenge
  Stream<ChallengeEvent> watchChallenges({String basePath});

  // Genera un nuevo challenge y lo escribe en vault/intel/challenge.json
  Future<String> issueChallenge({
    required String level,  // OPERATIONAL|TACTICAL|KERNEL|KERNEL-CORE
    required String project,
    required List<String> files,
    required String basePath,
  });
}

// Gate levels — mapeados desde Base2/ops-guard.ps1
enum GateLevel { blue, amber, orange, red, gold }
```

## Estructura de challenge.json (compatible con Vanguard Flutter App existente)
```json
{
  "challenge": "AUTH-20260325155100-abc12345",
  "timestamp": "2026-03-25T15:51:00Z",
  "level": "KERNEL",
  "project": "BASE2",
  "files": "ops-gov.ps1, GEMINI.md",
  "description": "CAPA-1: Cambios en reglas fundamentales (FOUNDATION)"
}
```

## DoD
- [ ] `watchChallenges()` detecta nuevos `challenge.json` en <500ms.
- [ ] `bindKey()` inserta `<ProjectId>` en el XML de clave.
- [ ] `validateKey()` rechaza claves de otro proyecto con error explícito.
- [ ] Compatible con el formato de `challenge.json` que espera la Vanguard Flutter App existente.
- [ ] Tests unitarios para bind/validate.
- [ ] Self-Audit Obligatorio (`gov audit`) verificado antes del baseline.

## ⚠️ NOTA CRÍTICA
NO es necesario arrancar Vanguard Flutter App si `gov.exe` está corriendo en watch mode.
Ambos pueden coexistir usando el mismo `challenge.json`.

## Baseline (requiere firma RSA del PO)
`gov baseline "S03-01: VanguardCore headless challenge engine" GATE-RED`
