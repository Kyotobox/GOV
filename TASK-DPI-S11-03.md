# TASK-DPI-S11-03: Session Lock HMAC

**Sprint**: S11-HOTFIX
**Label**: [SEC]
**CP**: 5
**Gate**: GATE-GOLD
**Modelo**: Gemini Flash

## Contexto
Resolver VUL-16. `session.lock` no está protegido criptográficamente, lo que permite a un atacante local alterar el nivel de fatiga, saltarse el fail-safe y evadir el control de `git_hash`.

## Scope
- `bin/antigravity_dpi.dart`
- `lib/src/telemetry/telemetry_service.dart`
- `TASK-DPI-S11-03.md`

## DoD
- [ ] Generar un HMAC (SHA-256) sobre el contenido del JSON cada vez que se escriba `session.lock` (usando una clave estática o UUID de máquina temporalmente).
- [ ] Añadir la llave `_mac` al JSON guardado.
- [ ] Al leer `session.lock` en `takeover` y `status`, recalcular y validar el HMAC. 
- [ ] Bloquear la ejecución con `[CRITICAL] KERNEL-VIOLATION` si el MAC es inválido o no existe.