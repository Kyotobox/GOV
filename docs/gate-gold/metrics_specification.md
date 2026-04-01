# Especificación Técnica: Métricas de Gobernanza [DPI-GATE-GOLD]

Este documento detalla la lógica matemática, la evolución de parámetros y los registros históricos de los indicadores de telemetría utilizados por el motor **Antigravity DPI v8.3.1**.

## 1. CUS (Context Utilization Score)
El **CUS** evalúa el nivel de fatiga cognitiva y la proximidad al límite de la ventana de contexto de la IA.

### Algoritmo de Cálculo (v8.3.x):
`CUS = (Turns * 1.2) + (Chats * 0.5) + Penalty_MAX_TOKENS + Output_Pressure`

#### Parámetros Técnicos:
| Parámetro | Valor | Rationale / Comportamiento Corregido |
| :--- | :--- | :--- |
| **Turns (Tool usage)** | 1.2 pts | Incremento por cada llamada a herramienta. |
| **Chats (User msg)** | 0.5 pts | Peso del historial de conversación. |
| **MAX_TOKENS Penalty** | +40.0 pts | **Corrección**: Evita la "deriva alucinatoria" bloqueando la sesión inmediatamente si el modelo trunca la salida. |
| **Scale Divisor** | 50.0 CP | **Ajuste v8.2.1**: Aumentado desde 30.0 para permitir sesiones más densas sin bloqueos prematuros. |

### Ejemplos de Escenarios Reales:

> [!TIP]
> **Escenario A: Operación Nominal**
> - 10 Herramientas (12 CP) + 4 Chats (2 CP) = **14 CP**.
> - **SHS**: (14/50) = 28%. Estado: **SAFE**.

> [!WARNING]
> **Escenario B: Truncamiento Crítico**
> - 5 Herramientas (6 CP) + Detección de `MAX_TOKENS` (+40 CP) = **46 CP**.
> - **SHS**: (46/50) = 92%. Estado: **LOCKED**.
> - *Nota: El sistema fuerza un `handover` para resetear el contexto.*

---

## 2. BHI (Bunker Health Index)
El **BHI** mide la degradación de la infraestructura y la integridad de seguridad. 

### Ponderación Evolutiva (70/30):
En la versión **v8.2.0**, se ajustó la ponderación para priorizar la **Integridad DNA** sobre la **Higiene de Archivos**.

1. **DNA Integrity (70% weight)**:
   - Falla de firma RSA o hash binario mismatch: **70.0 pts**.
   - *Rationale*: Un binario alterado es un riesgo de seguridad de nivel GOLD.
2. **System Hygiene (30% weight)**:
   - `Density_Tax`: `(Files / 20) * 15.0` pts.
   - `Zombie_Tax`: `ZombieCount * 3.0` pts.

### Comparativa Histórica de Ajustes:
- **v8.1.x**: Ponderación 50/50. El desorden en la raíz (temporales) podía bloquear al agente tanto como una falla de seguridad.
- **v8.2.0+**: Ponderación 70/30. Se permite mayor "ruido" en archivos si la firma del motor es válida.

---

## 3. SHS (Saturation/Dual Pulse)
El **SHS** consolidado sigue la regla del **Punto Más Débil** (High-Water Mark).

### Fórmula:
`SHS = max(CUS, BHI).round()`

#### Registros de Sesiones Críticas:
| Baseline | SHS Promedio | Observaciones |
| :--- | :--- | :--- |
| **v8.1.5** | 68% | Alta sensibilidad a archivos zombies. |
| **v8.2.1** | 42% | Mejora en fluidez tras ajuste del divisor de CP a 50. |
| **v8.3.1 (Actual)** | 8.3% | Fase inicial posterior a limpieza atómica (Nuclear Separation). |

---
**Protocolo**: DPI-GATE-GOLD  
**Firmado**: Arquitecto de Gobernanza Internal  
**Fecha**: 2026-03-31
