# TASK-DPI-S29-03: Master CUS Redesign (Deterministic Formula)

## Objetivo
Implementar el cálculo de CUS basado exclusivamente en presiones reales de tokens y tasas de truncamiento.

## Alcance Técnico
- Fórmula Maestra: `CUS = (Turns * 1.2) + (Input_Pressure * 50.0) + (Output_Pressure * 50.0) + (Truncation_Rate * 40.0) + immediateSpike`.
- `Input_Pressure`: `promptTokens / CONTEXT_WINDOW`.
- `Output_Pressure`: `candidatesTokens / OUTPUT_LIMIT`.
- `Truncation_Rate`: `Conteo('MAX_TOKENS') / Total de turnos`.
- Deprecación de `Chats (0.0 weight)`.

## Criterios de Aceptación
1. Resultados de CUS 100% predecibles con metadatos conocidos.
2. Los chats ya no impactan la fatiga cognitiva de forma aislada.
3. El `immediateSpike (15 pts)` se activa correctamente ante `MAX_TOKENS`.

---
**Protocolo**: [DPI-GATE-GOLD]  
**Estado**: TODO
