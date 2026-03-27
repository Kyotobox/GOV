# Orquestación de Tareas (BacklogManager)

**Ruta**: `lib/src/tasks/backlog_manager.dart`
**Nivel de Gobernanza**: GATE-RED

## 1. Resumen

El `BacklogManager` es el motor `GATE-RED` encargado de la orquestación y gestión del ciclo de vida de las tareas y sprints del proyecto `antigravity_dpi`. Su función principal es interpretar el `backlog.json` y los archivos `TASK-DPI-*.md` para determinar el estado actual del trabajo, asegurar la concurrencia de tareas y proporcionar el contexto necesario para otras operaciones de gobernanza.

## 2. Responsabilidades Clave

- **Carga y Parseo del Backlog**: Lee y deserializa el archivo `backlog.json`, que contiene la definición de todos los sprints y tareas.
- **Identificación de Sprint Activo**: Determina cuál es el sprint actualmente `IN_PROGRESS` o el siguiente `PENDING` en la secuencia.
- **Identificación de Tarea Activa**: Dentro del sprint activo, identifica la tarea `IN_PROGRESS` o la primera `PENDING`.
- **Verificación de Concurrencia**: Asegura que no haya múltiples tareas activas simultáneamente, previniendo la dispersión del foco.
- **Sincronización con `TASK-DPI-*.md`**: Se espera que cada tarea tenga un archivo `TASK-DPI-ID.md` asociado que define su alcance (`Scope`) y puntos de fatiga (`CP`).

## 3. Flujo de Operación

1.  **Carga del Backlog**: El `BacklogManager` se inicializa cargando el `backlog.json` desde la ruta base del proyecto.
2.  **Determinación del Contexto**:
    -   Cuando se invoca un comando que requiere el contexto de la tarea (ej. `gov act`, `gov context`), el manager busca el sprint con estado `IN_PROGRESS`.
    -   Si no hay un sprint `IN_PROGRESS`, busca el primer sprint `PENDING`.
    -   Dentro del sprint seleccionado, busca la tarea `IN_PROGRESS` o la primera `PENDING`.
3.  **Validación de Concurrencia (`checkConcurrency`)**:
    -   Este método es invocado por operaciones críticas (ej. `gov audit`, `gov act`) para asegurar que solo una tarea esté en progreso.
    -   Si detecta más de una tarea `IN_PROGRESS`, reporta una anomalía.
4.  **Actualización de Estado (Implícita)**: Aunque el `BacklogManager` no modifica directamente el `backlog.json` (esto se hace a través de comandos como `gov baseline` que actualizan el estado del sprint), sus métodos reflejan el estado actual del proyecto.

## 4. Integración con Otros Módulos

-   **CLI (`bin/antigravity_dpi.dart`)**: La interfaz de línea de comandos utiliza el `BacklogManager` para determinar el contexto de la tarea en casi todos los comandos operativos (ej. `audit`, `act`, `handover`, `takeover`, `baseline`, `context`).
-   **`ComplianceGuard`**: Depende del `BacklogManager` para obtener el ID de la tarea activa y así poder extraer el `Scope` del archivo `TASK-DPI-ID.md` correspondiente.
-   **`ForensicLedger`**: Utiliza el ID del sprint y la tarea activa proporcionados por el `BacklogManager` para registrar los eventos en el `HISTORY.md` con el contexto adecuado.
-   **`ContextEngine`**: Se basa en el `BacklogManager` para identificar la tarea activa y su sprint, lo que es crucial para generar el `ai_context.txt` focalizado.

## 5. Artefactos Relacionados

-   `backlog.json`: El archivo principal que define la estructura de sprints y tareas.
-   `TASK-DPI-*.md`: Archivos individuales que detallan cada tarea, incluyendo su `Scope` y `CP`.
-   `session.lock`: Aunque no es gestionado directamente por el `BacklogManager`, el estado de la sesión (`status`, `inherited_fatigue`) influye en cómo se interpretan las tareas activas en el contexto de un `takeover`.

## 6. Hardening y Seguridad

El `BacklogManager` contribuye a la seguridad al:
-   **Forzar la Concurrencia Única**: Al verificar que solo una tarea esté activa, reduce la complejidad y el riesgo de errores humanos o manipulaciones que podrían surgir de un estado de trabajo ambiguo.
-   **Proporcionar Contexto Definido**: Al vincular las operaciones a tareas específicas, facilita la trazabilidad y la auditoría de las acciones realizadas, ya que cada evento en el `ForensicLedger` está asociado a un `task ID`.