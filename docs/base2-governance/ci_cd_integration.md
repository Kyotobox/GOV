# Integración de antigravity_dpi en Pipelines CI/CD de Base2

**Ruta del Módulo Core**: `bin/antigravity_dpi.dart` (CLI)
**Nivel de Gobernanza**: GATE-RED (con puntos de escalada a GATE-GOLD)

## 1. Resumen

La integración de `antigravity_dpi` en los pipelines de Integración Continua y Despliegue Continuo (CI/CD) de los proyectos Base2 es crucial para automatizar la aplicación de la gobernanza y asegurar la calidad y seguridad del código de forma proactiva. Al ejecutar los comandos de `antigravity_dpi` en cada etapa del pipeline, se garantiza que los principios de "Cerca Eléctrica", integridad criptográfica y cumplimiento de scope se mantengan desde el desarrollo hasta la producción.

## 2. Propósito

-   **Automatización de la Gobernanza**: Aplicar automáticamente las reglas de gobernanza de `antigravity_dpi` sin intervención manual.
-   **Detección Temprana de Violaciones**: Identificar y bloquear cambios que no cumplen con las políticas de seguridad o scope en las primeras etapas del ciclo de desarrollo.
-   **Reforzar la Disciplina**: Asegurar que todos los desarrolladores adhieran a los estándares de codificación y procesos definidos por `antigravity_dpi`.
-   **Trazabilidad y Auditoría Continua**: Generar un registro inmutable de la conformidad en cada build, facilitando auditorías y el análisis forense.
-   **Reducción de Riesgos**: Minimizar la probabilidad de introducir vulnerabilidades o código no autorizado en el entorno de producción de Base2.

## 3. Comandos Clave para Integración CI/CD

Los siguientes comandos de `antigravity_dpi` son fundamentales para la integración en pipelines:

-   **`gov audit`**:
    -   **Uso**: Ejecutar al inicio de cada etapa del pipeline (ej. pre-build, pre-merge) para verificar la integridad criptográfica del kernel, detectar huérfanos y asegurar el cumplimiento del `Scope-Lock`.
    -   **Impacto**: Un fallo en `gov audit` debe detener el pipeline, indicando una violación crítica de la integridad o el scope.
    -   **Variante**: `gov audit --deep` para una auditoría forense completa de la cadena del `HISTORY.md`.

-   **`gov baseline`**:
    -   **Uso**: Ejecutar en puntos de integración críticos, como antes de un despliegue a producción o al finalizar un sprint. Sella el estado del kernel y requiere la aprobación del PO.
    -   **Impacto**: Un `baseline` fallido (ej. por falta de firma del PO o fallos de integridad) debe bloquear el avance del pipeline.

-   **`gov act`**:
    -   **Uso**: Puede ejecutarse periódicamente para registrar el pulso cognitivo y la actividad de la sesión, aunque su uso es más frecuente en entornos de desarrollo interactivos. En CI/CD, `gov audit` suele ser suficiente para la verificación.

-   **`gov pack`**:
    -   **Uso**: Generar un paquete de auditoría (`.zip`) del proyecto Base2, excluyendo archivos sensibles o irrelevantes. Útil para entregar artefactos a equipos de seguridad o auditores externos.
    -   **Impacto**: Siempre ejecuta un `gov audit` previo, asegurando que solo se empaqueten kernels íntegros.

-   **`gov detectOrphans`**:
    -   **Uso**: Ejecutar como parte de la auditoría o como un paso independiente para identificar archivos en el repositorio que no están referenciados en ningún manifiesto de integridad.
    -   **Impacto**: La presencia de huérfanos puede indicar código no gestionado o residuos de tareas anteriores, lo que podría ser una alerta o un bloqueo dependiendo de la política del proyecto.

## 4. Estrategias de Integración

### 4.1. Pre-Commit Hooks (Desarrollo Local)

-   Instalar `git hooks` (`gov hook install`) para ejecutar `gov audit` o `gov act --dry-run` antes de cada commit, proporcionando retroalimentación instantánea a los desarrolladores.

### 4.2. Pull Request / Merge Request

-   Configurar el pipeline para ejecutar `gov audit` en cada Pull Request. Esto asegura que el código propuesto cumpla con las políticas de gobernanza antes de ser fusionado.
-   El `Scope-Lock` (definido en `TASK-DPI-ID.md`) es especialmente relevante aquí, ya que `gov audit` verificará que los cambios se limiten al alcance de la tarea activa.

### 4.3. Build y Despliegue

-   Antes de generar un artefacto de despliegue, ejecutar `gov audit` para certificar la integridad del código que se va a compilar.
-   Antes de desplegar a entornos de staging o producción, ejecutar `gov baseline` para sellar el hito y obtener la aprobación del PO.

## 5. Hardening y Seguridad en CI/CD

-   **Credenciales Seguras**: Las claves RSA privadas del PO (necesarias para `gov baseline`) deben gestionarse de forma segura en el entorno CI/CD, utilizando secretos o vaults de credenciales.
-   **Entornos Aislados**: Ejecutar `antigravity_dpi` en contenedores o entornos aislados para evitar interferencias y garantizar la reproducibilidad.
-   **Registro Detallado**: Asegurar que la salida de `antigravity_dpi` se capture en los logs del pipeline para auditoría.
-   **Notificaciones**: Configurar notificaciones para alertar a los equipos sobre fallos de gobernanza.

## 6. Artefactos Relacionados

-   `base2_project/TASK-DPI-ID.md`: Define el `Scope` para el `Scope-Lock` en CI/CD.
-   `base2_project/vault/kernel.hashes`: Manifiesto de integridad verificado en cada `audit`.
-   `base2_project/vault/kernel.hashes.sig`: Firma del manifiesto.
-   `antigravity_dpi/HISTORY.md`: Registro de todas las operaciones de gobernanza.