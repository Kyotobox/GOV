# TASK-DPI-S11-01: PackEngine Audit Gap Fix

**Sprint**: S11-HOTFIX
**Label**: [SEC]
**CP**: 2
**Gate**: GATE-RED
**Modelo**: Gemini Flash

## Contexto
Resolver VUL-10 y VUL-13. El empaquetador actual (`PackEngine`) está fugando archivos críticos de la carpeta `vault/` y omitió carpetas estructurales en el ZIP de exportación, creando un "Audit Gap".

## Scope
- `lib/src/core/pack_engine.dart`
- `TASK-DPI-S11-01.md`

## DoD
- [ ] Modificar `excludes` en `PackEngine.pack` para excluir TODO el directorio `vault/` (no solo audit.log).
- [ ] Asegurar que el algoritmo empaqueta correctamente todo el contenido de `lib/` y `bin/`.
- [ ] Validar localmente ejecutando `gov pack` y revisando el ZIP.