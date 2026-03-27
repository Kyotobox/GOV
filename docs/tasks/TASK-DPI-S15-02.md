# TASK-DPI-S15-02: Ganchos Nativos Inescapables (gov hook install)

**Sprint**: S15-SYMBIOSIS
**Label**: [OPS]
**CP**: 2
**Gate**: GATE-RED
**Revisor**: [TECH]
**Modelo**: Gemini Flash

## Contexto
Inyectar `gov.exe` directamente en los *Git Hooks* locales (`.git/hooks/pre-commit` y `pre-push`) para que la gobernanza sea ineludible. Esto asegura que `gov audit` se ejecute automáticamente antes de cada commit o push.

## Scope
- `bin/antigravity_dpi.dart`
- `lib/src/core/hook_engine.dart` (Nuevo)
- `.git/hooks/pre-commit`
- `.git/hooks/pre-push`
- `TASK-DPI-S15-02.md`

## DoD
- [ ] Nuevo comando `gov hook install` implementado.
- [ ] `gov hook install` crea o actualiza `pre-commit` y `pre-push` en `.git/hooks/`.
- [ ] Los hooks invocan `dart run bin/antigravity_dpi.dart audit` y abortan la operación de Git si el audit falla.
- [ ] `gov hook install` registra una entrada `SNAP | HOOKS` en `HISTORY.md`.