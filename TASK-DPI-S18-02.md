# TASK-DPI-S18-02: Advanced Reporting (gov report with Roles)

**Sprint**: S18-UNIVERSAL-GOV
**Label**: [GOV]
**CP**: 3
**Gate**: GATE-BLUE
**Revisor**: [TECH]
**Modelo**: Gemini Flash

## Contexto
Desarrollar el comando `gov report` que genere resúmenes ejecutivos del `HISTORY.md`, incluyendo la capacidad de registrar y reportar acciones por roles de IA.

## Scope
- `bin/antigravity_dpi.dart`
- `lib/src/telemetry/forensic_ledger.dart`
- `lib/src/core/report_engine.dart` (Nuevo)
- `HISTORY.md`
- `TASK-DPI-S18-02.md`

## DoD
- [ ] `ForensicLedger.appendEntry` acepta un parámetro opcional `role`.
- [ ] Nuevo comando `gov report` implementado.
- [ ] `gov report` parsea `HISTORY.md` y genera un resumen agrupado por `role`.
- [ ] El reporte incluye métricas clave como CP total por rol, número de baselines, etc.