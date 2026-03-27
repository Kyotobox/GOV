# TASK-DPI-S04-02: compliance_guard.dart — Scope-Lock + Referential Integrity

**Sprint**: S04-COMPLIANCE
**Label**: [SEC]
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
- `bin/antigravity_dpi.dart`
- `test/compliance_guard_test.dart`
- `TASK-DPI-S04-02.md`

## Interfaz a Implementar
```dart
class ComplianceGuard {
  // Extrae los archivos/patrones permitidos de la sección "## Scope:" de un TASK-ID.md
  Future<List<String>> extractScopeFromMd({
    required String taskId,
    required String basePath,
  });

  // Verifica que los archivos modificados corresponden al scope dinámico estricto
  List<String> checkScopeLock({
    required List<String> allowedScope,
    required List<String> modifiedFiles,
  });

  // Verifica que existe un TASK-ID.md en el root del proyecto
  // con los campos Scope y CP declarados
  Future<bool> checkReferentialIntegrity({
    required String taskId,
    required String basePath,
  });

  // Bloquea el baseline si hay violaciones de scope o falta el TASK-ID.md
  // Lanza ComplianceException si no pasa
  Future<void> enforcePreBaseline({
    required String taskId,
    required List<String> modifiedFiles,
    required String basePath,
  });
}
```

## DoD
- [ ] extractScopeFromMd() parsea correctamente la lista de archivos de la sección "Scope".
- [ ] checkScopeLock() verifica contra el scope dinámico extraído y abandona el uso de labels.
- [ ] checkReferentialIntegrity() verifica que el TASK-ID.md existe y tiene `Scope:` y `CP:`.
- [ ] enforcePreBaseline() lanza excepción descriptiva antes de cualquier baseline.
- [ ] Tests: escenario con archivo fuera de scope detecta violación correctamente.

## Baseline
`gov baseline "S04-02: ComplianceGuard scope-lock implemented" GATE-ORANGE`
