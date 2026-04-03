# REPORTE FORENSE: CUS DETERMINÍSTICO [NUCLEUS-V9.2.0]

**Fecha**: 2026-04-02
**Protocolo**: SENTINEL v1.4.1
**Estado**: CERTIFICADO

## 1. Motivación
La migración de un sistema de conteo de turnos lineal a un modelo determinista de **Presión Cognitiva (CUS)** responde a la necesidad de mitigar la saturación por ventanas de contexto masivas (500k tokens) y límites de salida fluctuantes.

## 2. Algoritmo de Cálculo (DPI-GOLD)
El nuevo motor implementado en `PulseAggregator.dart` utiliza la siguiente fórmula:

$$CP = W_{turns} + 50 \cdot P_{input} + 50 \cdot P_{output} + 40 \cdot R_{truncation} + S_{immediate}$$

Donde:
- **$W_{turns}$**: Peso por interacción (Logs persistentes en `session_log.json`).
- **$P_{input}$**: Presión de Entrada ($\frac{\text{Total Prompt Tokens}}{500,000}$).
- **$P_{output}$**: Presión de Salida ($\frac{\text{Max Output Tokens}}{8,192}$).
- **$R_{truncation}$**: Tasa de Truncamiento (Eventos `MAX_TOKENS` / Total Turnos).
- **$S_{immediate}$**: Spike de fatiga (+15.0 pts) si el último turno fue truncado.

## 3. Umbrales de Gobernanza
| Estado | Rango CUS | Protocolo |
| :--- | :--- | :--- |
| **NOMINAL** | 0.0 - 34.9 | Operación Estándar |
| **WARNING** | 35.0 - 44.9 | Notificación al PO (DASHBOARD Amarilla) |
| **LOCKED** | 45.0+ | Bloqueo de Sesión & `gov handover` Mandatorio |

## 4. Trazabilidad de Auditoría
- **Archivo de Origen**: `vault/intel/session_log.json`
- **Motor de Evaluación**: `lib/src/services/pulse_aggregator.dart`
- **Firmante de Integridad**: Vanguard Agent Nucleus

---
**Certificado de Integridad de Cálculo**
*Sello Atómico: S30-CUS-CALIB*
