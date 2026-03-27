# TASK-DPI-S15-03: Simulador de Vuelo / Dry-Run (gov act --dry-run)

**Sprint**: S15-SYMBIOSIS
**Label**: [CLI]
**CP**: 3
**Gate**: GATE-BLUE
**Revisor**: [TECH]
**Modelo**: Gemini Flash

## Contexto
Permitir que la IA (o el desarrollador) pruebe si sus cambios romperán el `Scope-Lock` o los hashes *antes* de aplicarlos realmente, sin generar entradas en `HISTORY.md` ni consumir CP.

## Scope
- `bin/antigravity_dpi.dart`
- `lib/src/tasks/compliance_guard.dart`
- `TASK-DPI-S15-03.md`

## DoD
- [ ] Implementar la bandera `--dry-run` en el comando `gov act`.
- [ ] Cuando `--dry-run` está activo, `gov act` ejecuta `runAudit` pero no persiste el pulso ni registra entradas en `HISTORY.md`.
- [ ] La salida en consola indica claramente que es una simulación.