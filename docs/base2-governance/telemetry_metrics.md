# Telemetría de Salud del Sistema (SHS/CP para Base2)

**Ruta del Módulo Core**: `lib/src/telemetry/telemetry_service.dart` (dentro de `antigravity_dpi`)
**Nivel de Gobernanza**: GATE-GOLD

## 1. Resumen

La "Telemetría de Salud del Sistema" es un bloque de gobernanza que `antigravity_dpi` (nuestro Control Plane) extiende a los productos del ecosistema Base2. Su objetivo es calcular y proporcionar métricas objetivas sobre la "salud" (System Health Score - SHS) y la "fatiga cognitiva" (Cognitive Pulse - CP) de los proyectos Base2. Estas métricas, basadas en la actividad del repositorio y el historial de gobernanza, ofrecen indicadores tempranos de posibles problemas de calidad, sobrecarga en el desarrollo o riesgos técnicos, permitiendo intervenciones proactivas.

## 2. Propósito

-   **Visibilidad del Estado**: Proporcionar una visión clara y cuantificable del estado de salud de un proyecto Base2.
-   **Detección Temprana de Riesgos**: Identificar tendencias negativas en la calidad del código, la complejidad o la fatiga del equipo de desarrollo de Base2.
-   **Soporte a la Toma de Decisiones**: Ofrecer datos objetivos para la planificación de sprints, la asignación de recursos y la gestión de la deuda técnica en Base2.
-   **Persistencia de la Fatiga**: Asegurar que la "fatiga cognitiva" acumulada en un proyecto Base2 se herede entre sesiones, reflejando el costo real del desarrollo.

## 3. Componentes Involucrados (de `antigravity_dpi`)

Los siguientes módulos de `antigravity_dpi` colaboran para implementar este bloque de gobernanza en Base2:

-   **`TelemetryService` (`lib/src/telemetry/telemetry_service.dart`)**: Es el motor principal que calcula el SHS y el CP para un proyecto Base2, basándose en el historial de Git, el tamaño del código, la frecuencia de cambios y la fatiga heredada.
-   **`ForensicLedger` (`lib/src/telemetry/forensic_ledger.dart`)**: Registra las métricas de pulso calculadas para Base2 en el `HISTORY.md` de `antigravity_dpi`, proporcionando un registro inmutable de la evolución de la salud del proyecto.
-   **`IntegrityEngine` (`lib/src/security/integrity_engine.dart`)**: Utilizado para verificar la integridad del `session.lock` de Base2, donde se persiste la fatiga heredada (`inherited_fatigue`).
-   **`DashboardEngine` (`lib/src/dash/dashboard_engine.dart`)**: Genera el `DASHBOARD.md` para un proyecto Base2, visualizando las métricas de telemetría de forma clara y concisa.
-   **CLI (`bin/antigravity_dpi.dart`)**: Orquesta los comandos que calculan y muestran la telemetría de Base2 (ej. `gov base2 act`, `gov base2 status`).

## 4. Flujo de Operación en el Ecosistema Base2

1.  **Recopilación de Datos**:
    -   `antigravity_dpi` recopila datos relevantes del proyecto Base2, como el número de commits, líneas de código modificadas, frecuencia de `baseline`/`handover`, y el `inherited_fatigue` del `session.lock` de Base2.
    -   Estos datos se obtienen mediante comandos de Git y la lectura de archivos de gobernanza de Base2.

2.  **Cálculo del Pulso (`computePulse`)**:
    -   `TelemetryService` utiliza un algoritmo propietario para calcular el `System Health Score (SHS)` y el `Cognitive Pulse (CP)` de Base2.
    -   El `CP` es una medida de la fatiga cognitiva, que se acumula con cada operación y se hereda entre sesiones.
    -   El `SHS` es una medida inversa del `CP`, reflejando la "salud" general del proyecto.

3.  **Persistencia del Pulso (`persistPulse`)**:
    -   Las métricas calculadas se persisten en un archivo `intel_pulse.json` dentro del `vault` del proyecto Base2, y se registran en el `HISTORY.md` de `antigravity_dpi`.

4.  **Actualización del `session.lock`**:
    -   Durante las operaciones de `handover` en Base2, el `shs_at_close` y el `inherited_fatigue` se actualizan en el `session.lock` de Base2, asegurando la continuidad de la fatiga.

5.  **Visualización en el Dashboard**:
    -   `DashboardEngine` utiliza las métricas de telemetría para generar un `DASHBOARD.md` para el proyecto Base2, proporcionando una representación visual del estado de salud.

## 5. Hardening y Seguridad

-   **Cálculo Determinista**: Los algoritmos de cálculo de SHS/CP son deterministas, asegurando que los mismos datos de entrada siempre produzcan las mismas métricas.
-   **Persistencia Criptográfica**: Las métricas se registran en el `HISTORY.md` de `antigravity_dpi` (encadenado criptográficamente) y se anclan en el `session.lock` de Base2 (protegido por HMAC), previniendo la manipulación de los datos históricos.
-   **Transparencia**: Las métricas son visibles y auditables, fomentando la confianza y la responsabilidad.
-   **Self-Audit de `antigravity_dpi`**: La integridad de `antigravity_dpi` se verifica antes de cada operación, garantizando que la herramienta que calcula la telemetría de Base2 es confiable.

## 6. Artefactos Relacionados (en el contexto de un proyecto Base2)

-   `base2_project/vault/intel_pulse.json`: Archivo JSON con las últimas métricas de pulso calculadas para Base2.
-   `base2_project/DASHBOARD.md`: Dashboard generado para Base2.
-   `base2_project/session.lock`: Almacena el `inherited_fatigue` y `shs_at_close`.
-   `antigravity_dpi/HISTORY.md`: Registro forense de `antigravity_dpi` que incluye eventos de telemetría de Base2.
-   `antigravity_dpi/lib/src/telemetry/telemetry_service.dart`: Implementación del motor de telemetría.

## 7. Consideraciones Adicionales

-   **Umbrales de Alerta**: Se pueden definir umbrales para SHS/CP en Base2 que, al ser superados, activen alertas o incluso un `GATE-BLACK` si la situación es crítica.
-   **Personalización de Métricas**: El algoritmo de cálculo de SHS/CP podría ser configurable para adaptarse a las particularidades de cada proyecto Base2.
-   **Integración con Herramientas de Monitoreo**: Las métricas de telemetría pueden ser exportadas a sistemas de monitoreo externos para una visibilidad más amplia.