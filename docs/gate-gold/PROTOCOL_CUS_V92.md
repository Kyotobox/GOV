# PROTOCOLO_CUS_V92.md — NUCLEUS-V9.2 [DPI-GATE-GOLD]

> [!IMPORTANT]
> **SSoT de Métricas Deterministas**: Este documento define la lógica del `PulseAggregator` (v9.2). Reemplaza la lógica ponderada de v9.1 por un modelo de presión de contexto directo.

## 1. Algoritmo Maestro de CUS (v9.2.0)
El Context Utilization Score se calcula mediante una suma determinista de presiones de tokens y métricas de truncamiento.

### Fórmula Principal:
$$CUS = (T \times 1.2) + (P_i \times 50.0) + (P_o \times 50.0) + (R_t \times 40.0) + S_{i}$$

| Componente | Descripción | Cálculo |
| :--- | :--- | :--- |
| **$T$ (Turns)** | Peso por iteración | `logs.length * 1.2` |
| **$P_i$ (Input Pressure)** | Presión de Entrada | `TotalPromptTokens / 500,000` |
| **$P_o$ (Output Pressure)** | Presión de Salida | `MaxOutputTokens / 8,192` |
| **$R_t$ (Truncation Rate)** | Tasa de Truncamiento | `EventosMaxTokens / logs.length` |
| **$S_i$ (Immediate Spike)** | Impulso por Truncamiento | **+15.0** si el último log es `MAX_TOKENS` |

---

## 2. Límites de Arquitectura
- **Ventana de Contexto (CONTEXT_WINDOW)**: 500k Tokens.
- **Límite de Salida (OUTPUT_LIMIT)**: 8,192 Tokens.

---

## 3. Estados de Saturación (SHS)
El `PulseEvaluator` dispara estados basados en el valor de CUS:

| CUS | Estado | Protocolo |
| :--- | :--- | :--- |
| **0 - 34** | **NOMINAL** | Operación Continua |
| **35 - 44** | **WARNING** | Notificación Vanguard UI |
| **45 - 100** | **LOCKED** | Bloqueo de Sesión / Reset Requerido |

---

## 4. Auditoría de Hot-Capture
Toda captura de metadatos se realiza mediante el interceptor `session_log.json`, garantizando que el CUS sea una métrica forense verificable y no una estimación volátil.

*[v1.2.0] Protocolo Determinista Certificado — SENTINEL v9.2.0.*
