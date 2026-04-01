# TASK-DPI-S27-02: METRIC-EXPANSION

## Descripción
Cálculo de la métrica `output_utilization` comparando el conteo de tokens de la respuesta contra el límite máximo (`MAX_TOKENS`).

## Criterios de Aceptación
- Exposición proporcional del límite alcanzado (%).
- Inclusión en el `ContextState` (Contexto Saturado).
- Persistencia en el `ledger`.
