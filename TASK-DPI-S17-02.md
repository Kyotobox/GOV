# TASK-DPI-S17-02: Reconstitution Engine (gov restore)

**Sprint**: S17-RELIABILITY
**Label**: [SEC]
**CP**: 5
**Gate**: GATE-GOLD
**Revisor**: [ARCH]
**Modelo**: Gemini Flash

## Contexto
Implementar un comando `gov restore` que compare el estado actual del proyecto contra `vault/kernel.hashes` y revierta archivos corruptos a su último estado sellado.

## Scope
- `bin/antigravity_dpi.dart`
- `lib/src/core/reconstitution_engine.dart` (Nuevo)
- `lib/src/security/integrity_engine.dart`
- `TASK-DPI-S17-02.md`

## DoD
- [ ] Nuevo comando `gov restore` implementado.
- [ ] `gov restore` detecta archivos que no coinciden con `kernel.hashes`.
- [ ] Ofrece revertir los archivos detectados a su estado sellado (requiere `git checkout <hash> -- <file>`).
- [ ] `gov restore` registra una entrada `SNAP | RESTORE` en `HISTORY.md`.