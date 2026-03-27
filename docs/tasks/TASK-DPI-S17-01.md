# TASK-DPI-S17-01: TestGuard Integration

**Sprint**: S17-RELIABILITY
**Label**: [QA]
**CP**: 4
**Gate**: GATE-RED
**Revisor**: [TECH]
**Modelo**: Gemini Flash

## Contexto
Integrar la ejecución de pruebas unitarias como un paso obligatorio en `gov baseline`. Si las pruebas fallan, el baseline se aborta, impidiendo que código defectuoso sea sellado.

## Scope
- `bin/antigravity_dpi.dart`
- `lib/src/core/test_engine.dart` (Nuevo)
- `TASK-DPI-S17-01.md`

## DoD
- [ ] `gov baseline` invoca `dart test` (o el comando de prueba configurado para el proyecto).
- [ ] Si el comando de prueba retorna un código de salida distinto de 0, `gov baseline` aborta con `[CRITICAL] TEST-FAIL`.
- [ ] El resultado de la ejecución de pruebas se registra en `HISTORY.md`.