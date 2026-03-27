# Telemetría y Métricas (TelemetryService)

**Ruta**: `lib/src/telemetry/telemetry_service.dart`
**Nivel de Gobernanza**: GATE-GOLD

## 1. Resumen

El `TelemetryService` es el componente `GATE-GOLD` de `antigravity_dpi` responsable de calcular y firmar métricas de telemetría, como el System Health Score (SHS) y el Cognitive Pulse (CP). Estas métricas proporcionan una visión objetiva del estado del sistema y la fatiga cognitiva del equipo, siendo esenciales para la gestión de relevos y la toma de decisiones informadas.

## 2. Propósito

-   **Monitorización del Estado**: Proporcionar una visión cuantificable de la "salud" y "fatiga" del proyecto `antigravity_dpi` y los proyectos gobernados (ej. Base2).
-   **Detección Temprana de Riesgos**: Identificar tendencias negativas que puedan indicar problemas de calidad, sobrecarga o riesgos técnicos.
-   **Soporte a la Gobernanza**: Ofrecer datos objetivos para la planificación, asignación de recursos y gestión de la deuda técnica.
-   **Persistencia de la Fatiga**: Asegurar que la fatiga cognitiva acumulada se herede entre sesiones, reflejando el costo real del desarrollo.

## 3. Componentes Involucrados

-   **`TelemetryService` (`lib/src/telemetry/telemetry_service.dart`)**: El motor principal para el cálculo de SHS y CP.
-   **`ForensicLedger` (`lib/src/telemetry/forensic_ledger.dart`)**: Registra las métricas de pulso calculadas en el `HISTORY.md`.
-   **`IntegrityEngine` (`lib/src/security/integrity_engine.dart`)**: Utilizado para verificar la integridad del `session.lock`, donde se persiste la fatiga heredada.
-   **`DashboardEngine` (`lib/src/dash/dashboard_engine.dart`)**: Genera el `DASHBOARD.md` para visualizar las métricas.

## 4. Flujo de Operación

1.  **Recopilación de Datos**: El servicio recopila datos relevantes del proyecto, como el historial de Git, líneas de código modificadas, frecuencia de operaciones de gobernanza y la fatiga heredada del `session.lock`.
2.  **Cálculo del Pulso (`computePulse`)**: Utiliza un algoritmo propietario para calcular el `System Health Score (SHS)` y el `Cognitive Pulse (CP)`. El CP se acumula con cada operación y el SHS es una medida inversa.
3.  **Persistencia del Pulso (`persistPulse`)**: Las métricas calculadas se guardan en un archivo `intel_pulse.json` dentro del `vault` y se registran en el `HISTORY.md`.
4.  **Actualización del `session.lock`**: Durante operaciones como `handover`, el `shs_at_close` y el `inherited_fatigue` se actualizan en el `session.lock` para mantener la continuidad de la fatiga.
5.  **Visualización**: Las métricas se utilizan para generar un `DASHBOARD.md` que proporciona una representación visual del estado de salud.

## 5. Hardening y Seguridad

-   **Cálculo Determinista**: Los algoritmos de cálculo de SHS/CP son deterministas, garantizando resultados consistentes.
-   **Persistencia Criptográfica**: Las métricas se registran en el `HISTORY.md` (encadenado criptográficamente) y se anclan en el `session.lock` (protegido por HMAC), previniendo la manipulación de datos históricos.
-   **Transparencia**: Las métricas son visibles y auditables, fomentando la confianza y la responsabilidad.
-   **Self-Audit**: La integridad de `antigravity_dpi` se verifica antes de cada operación, asegurando la fiabilidad de la herramienta.

## 6. Artefactos Relacionados

-   `vault/intel_pulse.json`: Archivo JSON con las últimas métricas de pulso.
-   `DASHBOARD.md`: Dashboard generado.
-   `session.lock`: Almacena el `inherited_fatigue` y `shs_at_close`.
-   `HISTORY.md`: Registro forense de `antigravity_dpi`.