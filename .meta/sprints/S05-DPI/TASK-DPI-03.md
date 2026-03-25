# TASK-DPI-03: Refinamiento de CLI (Takeover Context)

## Descripción
Mejorar el comando `takeover` para que actúe como el primer filtro de contexto del PO al iniciar sesión.

## DoD
- [ ] El comando carga `backlog.json` del proyecto target.
- [ ] Muestra el primer ítem `PENDING` del sprint actual en consola.
- [ ] Calcula e imprime el `SHS` y `CP` actuales antes de permitir el inicio.
- [ ] Bloquea el proceso si el estado de `session.lock` no es `HANDOVER_SEALED`.
- [ ] Actualiza `session.lock` a `IN_PROGRESS` tras el éxito.
