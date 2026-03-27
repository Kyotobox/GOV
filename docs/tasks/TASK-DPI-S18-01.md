# TASK-DPI-S18-01: Dynamic Scope Engine (gov.yaml)

**Sprint**: S18-UNIVERSAL-GOV
**Label**: [ARCH]
**CP**: 5
**Gate**: GATE-GOLD
**Revisor**: [ARCH]
**Modelo**: Gemini Flash

## Contexto
Externalizar las reglas de `Scope-Lock` (actualmente hardcodeadas en `compliance_guard.dart`) a un archivo de configuración (`gov.yaml`) en la raíz de cada proyecto gobernado, permitiendo el agnosticismo de lenguaje.

## Scope
- `lib/src/tasks/compliance_guard.dart`
- `gov.yaml` (Nuevo archivo de configuración)
- `TASK-DPI-S18-01.md`

## DoD
- [ ] `ComplianceGuard` lee las reglas de `Scope` desde `gov.yaml`.
- [ ] `gov.yaml` permite definir patrones de archivos por tipo de rol (ej. `UI: [*.html, *.css]`).
- [ ] `gov audit` aplica las reglas dinámicas de `gov.yaml`.