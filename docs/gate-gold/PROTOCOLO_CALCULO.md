# PROTOCOLO_CALCULO.md — NUCLEUS-V9 [DPI-GATE-GOLD]

> [!IMPORTANT]
> **SSoT de Métricas**: Este documento define la lógica inmutable del `PulseAggregator` (v9.1). Cualquier discrepancia entre este documento y el código fuente es considerada una violación de integridad de Nivel 1.

## 1. CUS: Context Utilization Score (Fatiga Cognitiva)
El CUS mide la carga de trabajo y el consumo de contexto del modelo durante la sesión.

### Algoritmo de Cálculo (Pesos de Interacción)
Cada interacción suma puntos de Fatiga Cognitiva (CP):
- **Herramientas de Escritura** (`REPLACE_FILE_CONTENT`, `WRITE_TO_FILE`): **+1.8 CP**
- **Herramientas de Orquestación** (`RUN_COMMAND`, `SEARCH_WEB`): **+1.2 CP**
- **Herramientas de Consulta** (`VIEW_FILE`, `LIST_DIR`): **+0.5 CP**
- **Interacción de Chat**: **+0.3 CP**

### Penalizaciones y Modificadores
1. **Fricción de Ventana (ContextWindow)**:
   - Umbral Crítico: **80%** de la ventana de contexto (1M tokens).
   - Multiplicador: `1.0 + ((ContextRatio - 0.8) * 10)`.
   - Efecto: A partir del 80%, el costo de cada CP escala linealmente.
2. **Desbordamiento Hard**: 
   - Si `finish_reason == MAX_TOKENS`: **+45.0 CP** (Penalización instantánea).

---

## 2. BHI: Bunker Health Index (Estado del Búnker)
El BHI mide la salud estructural y la higiene operativa del repositorio.

### Ponderación de Componentes
1. **Integridad (70%)**: 
   - Si `verifySelf()` falla (DNA Mismatch): **70.0 Puntos**.
2. **Higiene (30%)**:
   - **Densidad (Density)**: `(Archivos en Raíz / 20) * 15.0`.
   - **Zombis (Zombies)**: `(Número de Archivos No Autorizados * 3.0)`, tope en **15.0**.
3. **Impuesto por Tiempo (Time Tax)**:
   - `(Minutos de Sesión / 30.0)`, tope en **10.0**.

---

## 3. SHS: Saturation Health Score (Pulso Global)
El SHS es la métrica maestra que determina el estado de la Gobernanza.

### Estados de Saturación
| SHS | Estado | Protocolo | Acción |
| :--- | :--- | :--- | :--- |
| **0 - 34** | NOMINAL | Continuidad | Operación estándar. |
| **35 - 44** | WARNING | Alerta Temprana | Notificación visual en Vanguard HUD. |
| **45 - 89** | LOCKED | Suspensión de Sesión | Bloqueo de escritura / Requerimiento de Reset. |
| **90 - 100** | SECURITY HOLD | Intervención Humana | Auditoría obligatoria / Takeover manual. |

### Cálculo del Valor SHS
- `SHS = max(CUS, BHI)` (Ponderado por el nivel de severidad del Evaluador).

---

## 4. Ejemplos de Escenarios
- **Nominal**: Sesión de 10 min, 5 herramientas de consulta, 2 de escritura. CUS: ~6 CP. BHI: 0 (Limpio). **SHS: 6**.
- **Saturación**: Sesión de 2 horas. CUS: 40 CP. **SHS: 85 (WARNING)**.
- **Compromiso**: Intrusión detectada (DNA Mismatch). BHI: 70. **SHS: 95 (LOCKED)**.

*[v1.1.0] Protocolo Hard-Gate sincronizado con Kernel NUCLEUS-V9.*
