# Protección del Alcance (ComplianceGuard)

**Ruta**: `lib/src/tasks/compliance_guard.dart`
**Nivel de Gobernanza**: GATE-RED

## 1. Resumen

El `ComplianceGuard` es un componente `GATE-RED` diseñado para hacer cumplir el principio de "Scope-Lock", una de las "Cercas Eléctricas" fundamentales definidas en `VISION.md`. Su función principal es prevenir la deriva de contexto (`scope-creep`) al asegurar que cualquier modificación de archivos se realice estrictamente dentro del alcance definido para la tarea activa. Actúa como un guardián que valida las rutas de los archivos modificados contra un conjunto de patrones permitidos, extraídos dinámicamente de la documentación de la tarea.

## 2. Responsabilidades Clave

- **Extracción Dinámica de Alcance**: Lee el archivo `TASK-DPI-ID.md` de la tarea activa para extraer los patrones de archivos y directorios permitidos en la sección `## Scope:`.
- **Verificación de Scope-Lock**: Compara los archivos modificados en el repositorio Git con el alcance permitido, identificando cualquier violación.
- **Normalización Robusta de Rutas**: Utiliza funciones de normalización de rutas para prevenir ataques de Path Traversal.
- **Gestión de Exenciones del Sistema**: Mantiene una lista de archivos y directorios del sistema que están exentos de las reglas de Scope-Lock.
- **Verificación de Integridad Referencial**: Asegura que el archivo `TASK-DPI-ID.md` exista y contenga las secciones `## Scope:` y `**CP**:`.

## 3. Flujo de Operación

1.  **Activación**: El `ComplianceGuard` es invocado principalmente por el comando `gov audit` (y, por extensión, por `gov act`, `gov baseline`, `gov handover`, `gov takeover`) antes de permitir que la operación continúe.
2.  **Integridad Referencial**: Primero, verifica que el `TASK-DPI-ID.md` de la tarea activa sea válido y contenga la información necesaria (`checkReferentialIntegrity`).
3.  **Extracción de Alcance**: Si la integridad referencial es correcta, extrae los patrones de alcance (`extractScopeFromMd`).
4.  **Obtención de Archivos Modificados**: Obtiene la lista de archivos modificados del repositorio Git (`git status --porcelain`).
5.  **Verificación de Scope-Lock**: Compara cada archivo modificado con los patrones de alcance permitidos y las exenciones del sistema (`checkScopeLock`).
6.  **Reporte de Violaciones**: Si se detectan archivos fuera del alcance, lanza una `ComplianceException`, deteniendo la operación.

## 4. Hardening y Seguridad

El `ComplianceGuard` es un componente crítico para la seguridad y la gobernanza del proyecto. Las siguientes mejoras de hardening han sido implementadas:

-   **Protección contra Path Traversal (VUL-19 Mitigado)**: Anteriormente, rutas maliciosas como `../` podían evadir las comprobaciones de alcance. *Mitigación (Sprint S13-IMMUTABILITY):* Se implementó una normalización robusta de rutas utilizando `p.canonicalize` y `p.isWithin` del paquete `path`. Esto asegura que todos los archivos se evalúen en su ruta canónica absoluta, impidiendo que un atacante manipule la ruta para acceder a archivos fuera del `basePath` del proyecto.
-   **Exenciones de Sistema Claras**: La lista `systemExemptions` define explícitamente los archivos que `gov.exe` gestiona internamente y que no deben ser restringidos por el Scope-Lock de una tarea. Esto evita falsos positivos y permite la operación normal del motor.
-   **Validación de `TASK-DPI-ID.md`**: La verificación de integridad referencial asegura que el `Scope` y el `CP` estén siempre presentes en los archivos de tarea, evitando que tareas malformadas comprometan el sistema.

## 5. Integración con Otros Módulos

-   **CLI (`bin/antigravity_dpi.dart`)**: Invoca el `ComplianceGuard` como parte del proceso de auditoría (`runAudit`).
-   **`BacklogManager`**: Proporciona el ID de la tarea activa, que el `ComplianceGuard` utiliza para cargar el `TASK-DPI-ID.md` correspondiente.
-   **`ContextEngine`**: Utiliza el `ComplianceGuard` para extraer el alcance de la tarea y así generar un `ai_context.txt` focalizado.

## 6. Artefactos Relacionados

-   `TASK-DPI-ID.md`: Archivos individuales que definen el alcance (`Scope`) y los puntos de fatiga (`CP`) de cada tarea.
-   `.git/`: El repositorio Git es la fuente de los archivos modificados que el `ComplianceGuard` evalúa.
-   `VISION.md`: Define la "Cerca Eléctrica" de "NO modificar archivos fuera del scope de la tarea activa", que el `ComplianceGuard` implementa.

## 7. Consideraciones Adicionales

El `ComplianceGuard` es un componente de seguridad proactivo. Su efectividad depende de la correcta definición del `Scope` en cada `TASK-DPI-ID.md`. Un `Scope` vacío o mal definido puede llevar a un bloqueo preventivo del sistema, lo que subraya la importancia de una documentación de tareas precisa.