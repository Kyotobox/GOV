# Estructura y Seguridad del Directorio `vault/`

## 1. Resumen

El directorio `vault/` es el repositorio central de secretos y artefactos criptográficos del ecosistema `antigravity_dpi`. No es un módulo en sí mismo, sino una ubicación crítica en el sistema de archivos que alberga la "verdad" del kernel: manifiestos de integridad, claves RSA, y el contexto focalizado para la IA. Su seguridad es primordial, y su diseño se basa en principios de acceso controlado, inmutabilidad y verificación criptográfica para proteger la integridad y confidencialidad de los datos sensibles.

## 2. Propósito

El propósito principal del directorio `vault/` es proporcionar un almacenamiento seguro y centralizado para los datos que son fundamentales para la gobernanza y la seguridad del proyecto. Esto incluye:

-   **Fuente de Verdad del Kernel**: `kernel.hashes` y su firma `kernel.hashes.sig`.
-   **Autorización Criptográfica**: Claves RSA públicas y privadas del Product Owner (PO).
-   **Contexto de la IA**: `ai_context.txt` para la focalización de la IA.
-   **Estado de la Sesión**: `session.lock` (aunque reside en la raíz del proyecto, su integridad y anclaje están intrínsecamente ligados a `vault/`).

## 3. Estructura y Contenidos Clave

El directorio `vault/` contiene los siguientes archivos y subdirectorios críticos:

-   `vault/kernel.hashes`: El manifiesto de integridad del kernel. Contiene un mapeo de rutas de archivos a sus hashes SHA-256 esperados. Es la "fuente de verdad" para el `IntegrityEngine`.
-   `vault/kernel.hashes.sig`: La firma RSA del archivo `kernel.hashes`. Generada por el `SignEngine` con la clave privada del PO, garantiza la autenticidad e inmutabilidad del manifiesto.
-   `vault/keys.json`: Un archivo JSON que vincula IDs de proyecto (o sprints) con las rutas a las claves privadas RSA correspondientes. Permite la gestión de múltiples claves para diferentes contextos.
-   `vault/po_public.xml`: La clave pública RSA del Product Owner. Utilizada para verificar firmas.
-   `vault/po_private.xml`: La clave privada RSA del Product Owner. Utilizada para generar firmas. **Este archivo debe ser protegido con el máximo rigor.**
-   `vault/ai_context.txt`: Un archivo generado por el `ContextEngine` que contiene fragmentos de código fuente y documentación relevantes para la tarea activa, utilizado por la IA para focalizar su análisis.
-   `vault/intel/`: Subdirectorio que contiene métricas volátiles de telemetría, como `session_turns.txt` y `chat_count.txt`, utilizadas por el `TelemetryService`.
-   `vault/.gov_rate`: Archivo utilizado por el mecanismo Anti-Loop (CLI Rate Limiting) para almacenar timestamps de invocaciones.
-   `vault/.gov_rate`: Archivo JSON que almacena los timestamps de las últimas invocaciones de la CLI para implementar el mecanismo de "Anti-Loop" (Rate Limiting).

## 4. Mecanismos de Seguridad Implementados

La seguridad del directorio `vault/` se refuerza mediante varios mecanismos:

-   **Firmas RSA**: Los manifiestos críticos (`kernel.hashes`) están firmados digitalmente con RSA, lo que permite al `IntegrityEngine` verificar su autenticidad y detectar cualquier manipulación.
-   **HMAC en `session.lock` (VUL-16 Mitigado)**: El archivo `session.lock` (que ancla el `ForensicLedger` y el estado de la sesión) está protegido por un Hash-based Message Authentication Code (HMAC). Esto previene la manipulación de su contenido, incluyendo el `ledger_tip_hash` y la `inherited_fatigue`.
-   **Exclusión de Empaquetado (VUL-10 Mitigado)**: El `PackEngine` excluye explícitamente el directorio `vault/` de los paquetes de exportación (`audit_export_*.zip`), previniendo la fuga de información sensible a auditores externos o entornos no controlados.
-   **Acceso Controlado por el Sistema**: Se asume que el sistema operativo subyacente impone permisos de archivo adecuados para restringir el acceso no autorizado al directorio `vault/`.
-   **Registro Forense**: Todas las operaciones significativas que interactúan con los contenidos del `vault/` (ej. `baseline`, `handover`, `takeover`) son registradas en el `HISTORY.md` por el `ForensicLedger`, proporcionando una pista de auditoría inmutable.
-   **Vinculación y Rotación Segura de Claves (VUL-02 Mitigado)**: Los comandos `gov vault bind-key` y `gov vault rotate-keys` permiten gestionar el ciclo de vida de las claves RSA de forma segura, evitando la exposición de rutas o material criptográfico en los argumentos de la CLI.
-   **Anti-Loop (Rate Limiting) (S16-03)**: El uso de `vault/.gov_rate` previene ataques de denegación de servicio o bucles accidentales al limitar el número de ejecuciones de la CLI en un corto período de tiempo.

## 5. Componentes que Interactúan con `vault/`

-   **`IntegrityEngine`**: Lee `kernel.hashes` y `kernel.hashes.sig` para verificaciones, y `session.lock` para el anclaje del ledger.
-   **`SignEngine`**: Utiliza las claves RSA (`po_public.xml`, `po_private.xml`) para firmar y verificar manifiestos y desafíos.
-   **`TelemetryService`**: Escribe métricas en `vault/intel/` y lee `session.lock` para la fatiga heredada.
-   **`ForensicLedger`**: Actualiza el `ledger_tip_hash` en `session.lock` y utiliza `vault/history.lock` para exclusión mutua.
-   **`PackEngine`**: Excluye `vault/` de los paquetes de exportación.
-   **`ContextEngine`**: Escribe `ai_context.txt` en `vault/`.
-   **`KeyGenerator`**: Utilizado por `gov vault rotate-keys` para generar nuevos pares de claves RSA.
-   **CLI (`gov.exe`)**: Gestiona el ciclo de vida de las claves a través de los subcomandos de `gov vault`.

## 6. Hardening y Evolución

El diseño y la implementación de la seguridad del `vault/` han evolucionado a través de varios sprints:

-   **Sprint S11-HOTFIX**: Mitigación de `VUL-10` (fuga de `vault/` en `pack`) y `VUL-16` (HMAC en `session.lock`).
-   **Sprint S12-INTEGRITY**: Mitigación de `VUL-02` (vinculación segura de claves) y `VUL-08` (firma de `kernel.hashes`).
-   **Sprint S13-IMMUTABILITY**: Mitigación de `VUL-11` (anclaje del `ForensicLedger` en `session.lock`).
-   **Sprint S16-FACTORY-OPS**: Implementación del mecanismo Anti-Loop (`.gov_rate`), Kill-Switch para sesiones zombie y auto-commit semántico en `baseline`.

## 7. Consideraciones Adicionales

La integridad del directorio `vault/` es tan fuerte como la seguridad del sistema de archivos subyacente. Es crucial que los permisos de acceso a este directorio sean los más restrictivos posibles, permitiendo solo al binario `gov.exe` y a usuarios autorizados interactuar con sus contenidos. La pérdida o compromiso de las claves privadas almacenadas aquí tendría un impacto devastador en la confianza y la gobernanza del proyecto.