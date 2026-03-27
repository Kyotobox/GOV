# UNIFICACIÓN DE GOBERNANZA: Vanguard Agent & Oráculo [DPI-GATE-GOLD]

Este documento consolida la arquitectura final del Kernel de Gobernanza, unificando los controles heredados de `Base2` con los nuevos protocolos de alta fricción de `antigravity_dpi`.

## 1. Jerarquía de Fricción (Niveles Hardened)

El sistema opera bajo el paradigma de **Fricción Sensorial y Cognitiva** para romper la inercia de "aprobación mecánica".

### ⚡️ BLACK-GATE (Núcleo Inmutable)
- **Alcance**: Lógica de `Baseline`, `Handover`, `Takeover` y Fórmulas Hard de SHS (15 archivos max / 20.0 zombie).
- **Fricción Extrema**: 
    - **Alertas Sensoriales**: Alarma sonora y destellos rojos en el Agente Vanguard.
    - **Interfaz Aleatoria**: Los botones de firma cambian de posición en cada desafío.
    - **Cooldown de 24h**: Tras la firma, el sistema entra en "modo lectura" por 24 horas antes de permitir otro cambio en el núcleo.
- **Identificadores**: Desafíos tipo `BLACK-RULE-CHANGE-[HASH]`.

### 🥇 STRATEGIC-GOLD (Constitución)
- **Alcance**: `VISION.md`, `GEMINI.md`, Certificados de Llaves.
- **Fricción**: Firma RSA-2048 + Hash explícito de cambios de reglas + Alerta visual persistente.
- **Restricción SHS**: < 30%.
- **Cooldown de 1h**.

### 🔴 OPERATIONAL-RED (Gestión de Sprints)
- **Alcance**: `backlog.json`, `DASHBOARD.md`, `task.md`.
- **Fricción**: Firma RSA Estándar.
- **Restricción SHS**: < 70%.

### 🥈 TACTICAL-SILVER (Software Factory)
- **Alcance**: Código fuente de productos finales (materiales de fábrica).
- **Fricción**: Auditoría Estructural (SHS < 90%). Si la maquinaria es íntegra, el producto es aceptado.

---

## 2. Nuevos Controles de Integridad (Checklist Unificado)

| Control | Fuente | Estado | Descripción |
| :--- | :--- | :--- | :--- |
| **Atomic Relay** | Legacy | ✅ | El `handover` genera un manifest firmado que el `takeover` valida obligatoriamente. |
| **Pulse Persistence** | Legacy | ✅ | El estado de SHS/Fatiga persiste entre sesiones para evitar "limpiezas de memoria" del operador. |
| **Self-Audit Binario** | Legacy | ✅ | El motor `gov.exe` se auto-certifica antes de tocar cualquier proyecto externo. |
| **LEDGER Inmutable** | Sugerencia | 🆕 | Registro de auditoría circular que se firma tras cada alerta de Black/Gold Gate. |
| **RECOVERY-SEED** | Sugerencia | 🆕 | Frase mnemónica de 24 palabras para recuperación de emergencia (Nivel Purple). |
| **DRILL Protocol** | Sugerencia | 🆕 | Comando `gov drill` para simular ataques y verificar la reacción del Agente Vanguard. |

---

## 3. Modelo de Doble Instancia (Stability vs. Operation)

Para evitar la contaminación del núcleo, se implementan dos entornos:
1.  **Instancia Operacional**: Donde ocurre el desarrollo diario (Software Factory).
2.  **Instancia Maestra (Kernel)**: Solo se actualiza mediante un `baseline` de nivel GOLD/BLACK. El binario `gov.exe` distribuido solo se compila desde esta instancia.

## 4. Protocolo de EMERGENCIA-PURPLE (Bypass Certificado)

En caso de pérdida del Agente Vanguard o fallo catastrófico del sistema de archivos:
- El uso de la **RECOVERY-SEED** permite forzar un `takeover` y re-emitir certificados.
- Este evento queda marcado permanentemente en el `HISTORY.md` como una **Violación de Protocolo Certificada**.

---

> [!CAUTION]
> **PARADIGMA DE NO-CONFIANZA**: Este sistema asume que tanto la IA como el Usuario son puntos de falla potenciales. El único punto de verdad es la inmutabilidad matemática protegida por fricción sensorial deliberada.
