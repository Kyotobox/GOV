# TASK-DPI-S27-03: SHS-WEIGHTING

## Descripción
Integrar la presión de salida (Tokens) en el cálculo del `cus` (Context Utilization Score) para forzar relevos ante riesgo de truncamiento.

## Criterios de Aceptación
- Un 100% de `output_utilization` debe equivaler a un 100% de `cus`.
- Alerta visual en el Vanguard Agent ante presión crítica (>80%).
- Registro de causa de fatiga (Motivo: Saturación de Salida).
