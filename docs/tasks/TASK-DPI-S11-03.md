# TASK-DPI-S11-03: Session Lock HMAC

**Sprint**: S11-HOTFIX
**Label**: [SEC]
**CP**: 5
**Gate**: GATE-GOLD
**Modelo**: Gemini Flash

## Contexto
Resolver VUL-16. `session.lock` no está protegido criptográficamente, lo que permite a un atacante local alterar el nivel de fatiga, saltarse el fail-safe y evadir el control de `git_hash`.

## Scope
- `lib/`
- `bin/`
- `vault/`
- `backlog.json`
- `session.lock`
- `task.md`
- `HISTORY.md`
- `TASK-DPI-S11-01.md`
- `TASK-DPI-S11-02.md`
- `TASK-DPI-S11-03.md`
- `diag_integrity.dart`
- `diag.log`
- `diag.txt`
- `audit_export_1774548131276.zip`
- `git_status.txt`
- `git_status_full.tmp`

## DoD
- [x] Generar un HMAC (SHA-256) sobre el contenido del JSON cada vez que se escriba `session.lock` (usando una clave estática o UUID de máquina temporalmente).
- [x] Añadir la llave `_mac` al JSON guardado.
- [x] Al leer `session.lock` en `takeover` y `status`, recalcular y validar el HMAC. 
- [x] Bloquear la ejecución con `[CRITICAL] KERNEL-VIOLATION` si el MAC es inválido o no existe.