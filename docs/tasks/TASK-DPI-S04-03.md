# TASK-DPI-S04-03: Integración de Forensic Ledger en CLI

**Sprint**: S04-COMPLIANCE
**Label**: [GOV]
**CP**: 3
**Gate**: GATE-AMBER
**Revisor**: [ARCH] Gemini Pro

## Contexto
Inyectar `ForensicLedger` en los comandos principales del CLI (`act`, `baseline`, `handover`, `takeover`) para asegurar que cada evento crítico genere una entrada inmutable en la cadena de bloques local (`HISTORY.md`).

## Scope
- `bin/antigravity_dpi.dart`
- `lib/src/tasks/compliance_guard.dart`
- `lib/src/telemetry/forensic_ledger.dart`
- `lib/src/tasks/backlog_manager.dart`
- `TASK-DPI-S04-03.md`

## DoD
- [ ] `gov act` registra entrada en el ledger.
- [ ] `gov baseline` registra entrada en el ledger indicando sellado.
- [ ] `gov handover` y `gov takeover` registran el inicio/cierre de ciclo.
- [ ] Integridad referencial y Scope-Lock validados vía `gov audit`.

## Baseline
`gov baseline "S04-03: Forensic Ledger CLI integration" GATE-AMBER`
