# TASK-A01-03: VANGUARD-DASHBOARD (Diferenciación de HUD)

## Contexto
El Agente Vanguard debe proporcionar una interfaz visual clara y reactiva que refleje el estado de gobernanza del búnker. Esta tarea se centra en la diferenciación del HUD según el rol y la criticidad de las métricas.

## Objetivos
- [x] Sincronizar el modelo de datos `DualPulseData` con la UI del Vanguard Agent.
- [ ] Implementar degradado dinámico en el HUD basado en el valor de **SHS** (Verde > Naranja > Rojo).
- [ ] Asegurar que el `session_uuid` se muestre en el dashboard para trazabilidad de sesión.
- [ ] Validar la visualización de "Zombis" y "Swell" en la sección de Higiene.

## Estado Actual
- **Mecánica de Suspensión**: Implementada en el Kernel (Hard Gates).
- **Telemetría**: Persistencia en `intel_pulse.json` operativa.
- **HUD**: Requiere mapeo visual de las nuevas métricas (CUS/BHI).

## Próximos Pasos
1. Refactorizar el `DashboardProvider` para consumir la estructura `hygiene` y `context` del pulso.
2. Añadir disparadores de audio para estados `LOCKED` (Opcional/Futuro).

---
*Estado: IN_PROGRESS*
*Sprint: A01-GOVERNANCE-EVO*
