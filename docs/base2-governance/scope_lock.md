# Control de Cumplimiento (Scope-Lock para Base2)

**Ruta del Módulo Core**: `lib/src/tasks/compliance_guard.dart` (dentro de `antigravity_dpi`)
**Nivel de Gobernanza**: GATE-RED

## 1. Resumen

El "Control de Cumplimiento (Scope-Lock)" es un bloque de gobernanza que `antigravity_dpi` (nuestro Control Plane) aplica a los productos del ecosistema Base2. Su función es hacer cumplir el principio de "Cerca Eléctrica" de **no modificar archivos fuera del alcance de la tarea activa**. `antigravity_dpi` asegura que los cambios en Base2 se realicen estrictamente dentro de las áreas de código designadas para una tarea específica, previniendo la deriva de contexto (`scope-creep`) y la introducción de cambios no autorizados.

## 2. Propósito

-   **Prevenir la Deriva de Contexto**: Asegurar que el desarrollo en Base2 se mantenga enfocado en la tarea asignada, evitando cambios accidentales o no planificados en otras áreas del código.
-   **Reforzar la Disciplina de Desarrollo**: Imponer una estructura y un control sobre dónde y cómo se pueden realizar modificaciones en el código base de Base2.
-   **Reducir la Superficie de Ataque**: Limitar las áreas donde se pueden introducir cambios reduce las oportunidades para la inyección de código malicioso o errores.
-   **Mejorar la Trazabilidad**: Vincular explícitamente los cambios de archivos a una tarea específica facilita la auditoría y la comprensión del impacto de cada modificación.

## 3. Componentes Involucrados (de `antigravity_dpi`)

Los siguientes módulos de `antigravity_dpi` colaboran para implementar este bloque de gobernanza en Base2:

-   **`ComplianceGuard` (`lib/src/tasks/compliance_guard.dart`)**: Es el motor principal que extrae el alcance de la tarea de Base2, compara los archivos modificados con este alcance y detecta violaciones.
-   **`BacklogManager` (`lib/src/tasks/backlog_manager.dart`)**: Proporciona el ID de la tarea activa de Base2, que `ComplianceGuard` utiliza para cargar el archivo `TASK-DPI-ID.md` correspondiente.
-   **CLI (`bin/antigravity_dpi.dart`)**: Orquesta la ejecución de la verificación de Scope-Lock, principalmente como parte del comando `gov audit` (y por extensión, `gov act`, `gov baseline`, etc.).
-   **`ForensicLedger` (`lib/src/telemetry/forensic_ledger.dart`)**: Registrará las violaciones de Scope-Lock en el `HISTORY.md` de `antigravity_dpi`, proporcionando un registro inmutable de los intentos de incumplimiento.

## 4. Flujo de Operación en el Ecosistema Base2

1.  **Identificación de Tarea Activa**: `antigravity_dpi` (a través de `BacklogManager`) identifica la tarea activa en el proyecto Base2.

2.  **Extracción del Alcance**: `ComplianceGuard` lee el archivo `TASK-DPI-ID.md` de la tarea activa de Base2 y extrae los patrones de archivos y directorios definidos en la sección `## Scope`.

3.  **Obtención de Archivos Modificados**: `antigravity_dpi` obtiene una lista de los archivos modificados en el repositorio Git del proyecto Base2 (ej. usando `git status --porcelain`).

4.  **Verificación de Scope-Lock**: `ComplianceGuard` compara cada archivo modificado con los patrones de alcance extraídos y con una lista de exenciones del sistema (archivos que `antigravity_dpi` gestiona internamente y no deben ser restringidos).

5.  **Detección y Respuesta a Violaciones**:
    -   Si se detecta que un archivo modificado no está dentro del alcance permitido, `ComplianceGuard` lanza una `ComplianceException`.
    -   Esta excepción detiene la operación en curso (ej. `baseline`, `handover`) y se registra una alerta crítica en el `HISTORY.md` de `antigravity_dpi`.

## 5. Hardening y Seguridad

-   **Protección contra Path Traversal (VUL-19 Mitigado)**: `ComplianceGuard` utiliza normalización robusta de rutas (`p.canonicalize`, `p.isWithin`) para prevenir que rutas maliciosas (`../`) evadan las comprobaciones de alcance.
-   **Integridad Referencial**: `ComplianceGuard` verifica que el `TASK-DPI-ID.md` de Base2 exista y contenga las secciones `## Scope` y `**CP**`, asegurando que el alcance esté siempre definido.
-   **Exenciones de Sistema Claras**: Una lista `systemExemptions` explícita evita falsos positivos para archivos internos de `antigravity_dpi` o de gobernanza de Base2.
-   **Self-Audit de `antigravity_dpi`**: La integridad del propio `IntegrityEngine` de `antigravity_dpi` es verificada por el `Self-Audit`, garantizando que la herramienta que impone el Scope-Lock en Base2 es confiable.

## 6. Artefactos Relacionados (en el contexto de un proyecto Base2)

-   `base2_project/TASK-DPI-ID.md`: Archivos de tarea que definen el `Scope` para cada tarea de Base2.
-   `base2_project/.git/`: Repositorio Git, fuente de los archivos modificados.
-   `antigravity_dpi/lib/src/tasks/compliance_guard.dart`: Implementación del motor de Scope-Lock.
-   `antigravity_dpi/HISTORY.md`: Registro forense de `antigravity_dpi` que incluye eventos de violaciones de Scope-Lock.

## 7. Consideraciones Adicionales

-   **Definición Precisa del Alcance**: La efectividad del Scope-Lock depende directamente de la precisión y claridad con la que se define el `Scope` en cada `TASK-DPI-ID.md` de Base2. Un alcance demasiado restrictivo puede obstaculizar el desarrollo, mientras que uno demasiado laxo puede comprometer la gobernanza.
-   **Integración con CI/CD**: La verificación de Scope-Lock es ideal para integrarse en los pipelines de CI/CD de Base2, ejecutándose automáticamente en cada pull request o antes de la fusión de código.