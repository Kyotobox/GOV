# GEMINI.md — antigravity_dpi [DPI-GATE-GOLD]

> [!IMPORTANT]
> **PROTOCOLO DE VERDAD ATÓMICA**: La IA no puede inferir el estado de un proyecto gobernado. Debe consultar `gov audit` o los motores de integridad directamente. Ningún cambio en lógica de cálculo se acepta sin pruebas unitarias (`test/`).

## 1. SELECTOR DE ROL
Para este proyecto, el rol es **Arquitecto de Gobernanza (Interno)**. El enfoque es la robustez del motor, no la UI.

## 2. REGLAS CRÍTICAS (Anti-Alucinación)
1. **Self-Audit Obligatorio**: Antes de cualquier commit, el binario debe certificar su propio código fuente.
2. **Determinismo Unitario**: Toda nueva función aritmética (`Pulse`, `SHS`) requiere un test unitario en `test/` que verifique la precisión con datos de prueba.
3. **Draft-check Externo**: Prohibido sugerir "handover" si el `SHS` ha caído por debajo del 90% sin una justificación técnica atada a una `TASK-DPI-ID`.

## 3. JERARQUÍA SSoT
1. **VISION.md** (Identidad y Cercas Eléctricas).
2. **GEMINI.md** (Protocolos de la IA).
3. **TASK-DPI-* .md** (Documentos de Tarea).

## 4. GATE SYSTEM
- **GATE-GOLD**: Motor de Integridad (`lib/src/security/`), Telemetría y Criptografía. Requiere firma RSA.
- **GATE-RED**: Orquestación de Sprints, Gestión de Backlog y CLI.

## 5. PROTOCOLO DE RELEVOS (Handover/Takeover)
1. **Relay Atómico**: Cada sesión debe terminar con `gov handover`. El relay generado debe contener el hash de Git y la firma RSA del PO.
2. **Continuidad Certificada**: `gov takeover` es el único método autorizado para reanudar el trabajo sobre el Kernel. Si el audit de integridad falla, la toma de posesión debe ser bloqueada.
3. **Persistencia del Pulso**: El estado SHS final de una sesión debe persistir en el Relay para asegurar que el analista entrante comprenda el nivel de fatiga cognitiva heredado.

*[v1.1.0] Protocolo extendido con persistencia de sesiones.*
