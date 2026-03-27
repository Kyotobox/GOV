# TASK-DPI-S16-03: Mecanismo Anti-Loop (CLI Rate Limiting)

**Sprint**: S16-FACTORY-OPS
**Label**: [PERF]
**CP**: 3
**Gate**: GATE-RED
**Revisor**: [TECH]
**Modelo**: Gemini Flash

## Contexto
Proteger el `HISTORY.md` y la telemetría de IAs que entran en ciclos infinitos de ensayo y error, limitando la frecuencia de invocación del CLI.

## Scope
- `bin/antigravity_dpi.dart`
- `vault/.gov_rate` (Nuevo archivo temporal para registro de timestamps)
- `TASK-DPI-S16-03.md`

## DoD
- [ ] Implementar un *rate-limiter* en la entrada de `bin/antigravity_dpi.dart`.
- [ ] Si el CLI es invocado más de 3 veces en 15 segundos, el motor lanza un `[CRITICAL] ANTI-LOOP ACTIVATED` y hace `exit(1)`.
- [ ] El evento de `ANTI-LOOP` se registra en `HISTORY.md` como un `ALERT`.