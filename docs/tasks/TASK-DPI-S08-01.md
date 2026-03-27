# TASK-DPI-S08-01: Persistencia de Telemetría (SHS/CP)

**Objetivo**: Implementar la persistencia de la fatiga cognitiva (SHS) y los puntos de complejidad (CP) en el `HISTORY.md` tras cada `act`.
**CP**: 2

## Scope
- `lib/src/telemetry/telemetry_service.dart`
- `lib/src/telemetry/forensic_ledger.dart`
- `HISTORY.md`

## Pasos
1. [ ] Modificar `gov status` para reflejar la fatiga heredada de la sesión anterior.
2. [ ] Asegurar que `gov act` verifique la integridad del kernel antes de actuar y persista el pulso firmado.
3. [ ] Probar la persistencia tras un ciclo completo de `act` -> `takeover`.
