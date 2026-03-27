# TASK-DPI-S16-02: Kill-Switch de Sesiones Zombie

**Sprint**: S16-FACTORY-OPS
**Label**: [SEC]
**CP**: 3
**Gate**: GATE-RED
**Revisor**: [TECH]
**Modelo**: Gemini Flash

## Contexto
Implementar un mecanismo de expiración forzada para sesiones inactivas, previniendo bloqueos permanentes del repositorio si un agente (o desarrollador) abandona la sesión sin hacer `handover`.

## Scope
- `bin/antigravity_dpi.dart`
- `lib/src/telemetry/telemetry_service.dart`
- `TASK-DPI-S16-02.md`

## DoD
- [ ] `gov act` y `gov audit` verifican el `timestamp` en `session.lock`.
- [ ] Si la sesión excede 8 horas de antigüedad, el motor lanza un `[CRITICAL] SESSION-EXPIRED` y exige `gov handover --force`.
- [ ] El `Kill-Switch` se registra en `HISTORY.md` como un evento `ALERT`.