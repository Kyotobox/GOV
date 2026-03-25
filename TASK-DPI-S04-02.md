# TASK-DPI-S04-02: compliance_guard.dart — Scope-Lock + Referential Integrity

**Sprint**: S04-COMPLIANCE
**Label**: [DATA]
**CP**: 5
**Gate**: GATE-ORANGE
**Revisor**: [ARCH] Gemini Pro
**Modelo**: Gemini Flash

## Contexto
Implementar en Dart las reglas de `Invoke-ScopeLock` (`ops-audit.ps1` L381-412) y
la Regla de Integridad Referencial de `GEMINI.md` §2 punto 5.
**Referencia Base2**: `Base2/ops-audit.ps1` líneas 381-412.
**Referencia Base2**: `Base2/GEMINI.md` §2 Protocolo Obligatorio.

## Scope
- `lib/src/tasks/compliance_guard.dart`

## Interfaz a Implementar
```dart
class ComplianceGuard {
  // Verifica que los archivos modificados (git diff) corresponden al label de la tarea activa
  // Retorna lista de violaciones (vacía = OK)
  Future<List<ScopeViolation>> checkScopeLock({
    required String activeTaskLabel,  // UI|DATA|SHELL|GOV|PLAN|AUDIT|SEC
    required List<String> modifiedFiles,
  });

  // Verifica que existe un TASK-ID.md en el root del proyecto
  // con los campos Scope y CP declarados
  Future<ReferentialCheck> checkReferentialIntegrity({
    required String taskId,
    required String basePath,
  });

  // Bloquea el baseline si hay violaciones de scope o falta el TASK-ID.md
  // Lanza ComplianceException si no pasa
  Future<void> enforcePreBaseline({
    required String taskId,
    required String basePath,
  });
}

// Scope permitido por label (migrado de ops-audit.ps1)
const Map<String, List<RegExp>> scopeRules = {
  'UI':    [RegExp(r'lib/.*\.dart'), RegExp(r'assets/.*')],
  'DATA':  [RegExp(r'lib/.*\.dart')],
  'SHELL': [RegExp(r'.*\.ps1'), RegExp(r'.*\.bat'), RegExp(r'pubspec\.yaml')],
  'GOV':   [RegExp(r'ops-.*\.ps1'), RegExp(r'.*\.md'), RegExp(r'GEMINI\.md')],
  'SEC':   [RegExp(r'lib/src/security/.*'), RegExp(r'vault/.*')],
  'PLAN':  [RegExp(r'.*\.md'), RegExp(r'\.meta/.*')],
};
```

## DoD
- [ ] `checkScopeLock()` replica la lógica de `Invoke-ScopeLock` para todos los labels.
- [ ] `checkReferentialIntegrity()` verifica que el TASK-ID.md existe y tiene `Scope:` y `CP:`.
- [ ] `enforcePreBaseline()` lanza excepción descriptiva antes de cualquier baseline.
- [ ] Tests: escenario con archivo fuera de scope detecta violación correctamente.

## Baseline
`gov baseline "S04-02: ComplianceGuard scope-lock implemented" GATE-ORANGE`
