# TASK-DPI-S10-01: Orquestador de Auditoría Transversal

**Sprint**: S10-FLEET
**Label**: [OPS]
**CP**: 3
**Gate**: GATE-RED
**Revisor**: [GOV] Fleet Validator
**Modelo**: Gemini Flash

## Contexto
Para escalar la gobernanza a todo el ecosistema Base2 sin romper la Verdad Atómica aislada de cada proyecto, necesitamos un script orquestador (`gov-fleet-audit.bat`) que ejecute secuencialmente el CLI sobre múltiples directorios. Al finalizar, un rol validador debe evaluar el reporte resultante.

## Scope
- `bin/antigravity_dpi.dart`
- `lib/src/tasks/compliance_guard.dart`
- `gov-fleet-audit.bat`
- `fleet_report.txt`
- `fleet_details.log`
- `TASK-DPI-S10-01.md`

## DoD
- [ ] Crear el script `gov-fleet-audit.bat` en la raíz (para iterar sobre subcarpetas de Base2).
- [ ] El script debe aceptar una lista de rutas de repositorios (ej. `vanguard_agent`, `api_gateway`).
- [ ] Debe invocar `gov --path <ruta> audit` para cada directorio y capturar el código de salida (`%errorlevel%`).
- [ ] Si un audit falla (`exit(1)`), debe registrar el `KERNEL-VIOLATION` pero continuar con el siguiente repositorio para no perder visibilidad global.
- [ ] Consolidar los resultados en un archivo `fleet_report.txt` indicando [✅] o [❌] para cada proyecto.
- [ ] **Evaluación del Rol**: El `[GOV] Fleet Validator` debe revisar visualmente el `fleet_report.txt` y firmar la tarea dando su aprobación de que el script funciona correctamente.