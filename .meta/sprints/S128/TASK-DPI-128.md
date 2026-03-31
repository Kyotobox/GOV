# TASK-DPI-128: Hardening de Estamina Cognitiva (v5)

## 1. Objetivo
Implementar un modelo de estamina atómica e ineludible que elimine el "maquillaje" del enfriamiento por tiempo y lo reemplace por una gestión de fatiga basada en eventos de gobernanza activos.

## 2. Definición de Hecho (DoD)
- [ ] Eliminación total de `coolingRelief` (tiempo) en `gov.dart`.
- [ ] Implementación de `DynamicCostEngine` (Ponderación de Herramientas).
- [ ] Implementación de `StrategicRelief` (Bonificaciones solo >70% SHS por Baseline/TaskDone).
- [ ] Persistencia de `stamina_anchor.json` para rastreo diferencial.
- [ ] Verificación de salto de SHS en repositorios saturados (ej. Base2).

## 3. Especificaciones Técnicas

### Pesos de CP (V5):
- **Research (view_file, etc)**: 0.2 CP
- **Chat (Diálogo)**: 0.5 CP
- **Execution (commands)**: 1.5 CP
- **Modification (writes)**: 2.0 CP

### Bonos de Alivio (>70% SHS):
- **Cierre de Subtarea**: -4.0 CP
- **Sello de Baseline**: -15.0 CP
- **Omni-Sync**: -8.0 CP

## 4. Plan de Ejecución
1.  **Anclaje**: Generar `.meta/stamina_anchor.json` con el estado actual de tareas completadas.
2.  **Refactor**: Implementar los nuevos pesajes y eliminar el enfriamiento por tiempo en `CognitiveEngine`.
3.  **Auditoría**: Verificar que el SHS de `Base2` suba del 25% al 55% (~12.4 CP -> ~27.4 CP).

---
*Referencia: SSoT docs/SHS_V5_EVOLUTION.md*
