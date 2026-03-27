# Registro Forense Inmutable (HISTORY.md para Base2)

**Ruta del Módulo Core**: `lib/src/telemetry/forensic_ledger.dart` (dentro de `antigravity_dpi`)
**Nivel de Gobernanza**: GATE-GOLD

## 1. Resumen

El "Registro Forense Inmutable" es el mecanismo mediante el cual `antigravity_dpi` (nuestro Control Plane) mantiene una pista de auditoría completa y a prueba de manipulaciones para los productos del ecosistema Base2. Cada acción significativa (despliegues, cambios de configuración, auditorías, etc.) realizada en un proyecto Base2 y supervisada por `antigravity_dpi` se registra en un archivo `HISTORY.md` específico para ese proyecto. Este historial está encadenado criptográficamente, lo que significa que cualquier intento de alteración de un registro pasado invalidaría la cadena, siendo detectado por el `IntegrityEngine`.

## 2. Propósito

-   **Trazabilidad Completa**: Proporcionar un registro detallado de todas las operaciones y eventos en el ciclo de vida de un producto Base2.
-   **Inmutabilidad del Historial**: Asegurar que una vez que un evento ha sido registrado, no puede ser modificado o eliminado sin ser detectado.
-   **Soporte para Auditorías**: Servir como la fuente primaria de información para auditorías internas y externas, demostrando el cumplimiento de los procesos y la gobernanza.
-   **Análisis Post-Incidente**: Facilitar la investigación de incidentes al proporcionar un registro cronológico y verificado de los eventos.

## 3. Componentes Involucrados (de `antigravity_dpi`)

Los siguientes módulos de `antigravity_dpi` colaboran para implementar este bloque de gobernanza en Base2:

-   **`ForensicLedger` (`lib/src/telemetry/forensic_ledger.dart`)**: Es el motor principal que gestiona la adición de nuevas entradas al `HISTORY.md` de un proyecto Base2, calculando el hash de la línea anterior para mantener la cadena criptográfica.
-   **`IntegrityEngine` (`lib/src/security/integrity_engine.dart`)**: Contiene la función `verifyChain` (S19-FORTRESS) que valida la integridad de la cadena de hashes en el `HISTORY.md` de Base2, y `updateLedgerAnchor` que ancla el hash de la última entrada en el `session.lock` de Base2.
-   **`session.lock` (de Base2)**: Archivo que almacena el `ledger_tip_hash`, el hash de la última entrada válida en el `HISTORY.md` de Base2, protegido por un HMAC.
-   **`VanguardCore` (`lib/src/security/vanguard_core.dart`)**: Puede emitir desafíos `GATE-BLACK` si se detecta una ruptura crítica en la cadena forense de Base2.

## 4. Flujo de Operación en el Ecosistema Base2

1.  **Inicialización del Ledger**:
    -   Cuando `antigravity_dpi` interactúa por primera vez con un proyecto Base2 que no tiene un `HISTORY.md`, el `ForensicLedger` lo inicializa con una cabecera estándar y una primera entrada `BASE` con un `PrevHash` de ceros.

2.  **Registro de Eventos (`appendEntry`)**:
    -   Cualquier operación significativa realizada por `antigravity_dpi` en un proyecto Base2 (ej. `baseline`, `handover`, `pack`, `audit`, `deploy`) invoca al `ForensicLedger` para añadir una nueva entrada.
    -   Antes de añadir la nueva entrada, el `ForensicLedger` lee la última línea del `HISTORY.md` existente y calcula su hash SHA-256. Este hash se convierte en el `PrevHash` de la nueva entrada.
    -   La nueva entrada se formatea con `Timestamp`, `Role` (ej. `AI`, `PO`, `CI/CD`), `SessionID`, `PrevHash`, `Type` (ej. `EXEC`, `SNAP`, `ALERT`, `BASE`), `Task` y `Detail`.
    -   La entrada se añade al final del `HISTORY.md` de Base2.

3.  **Anclaje del Ledger (`updateLedgerAnchor`)**:
    -   Después de cada nueva entrada, el `ForensicLedger` invoca al `IntegrityEngine` para actualizar el `ledger_tip_hash` en el `session.lock` del proyecto Base2.
    -   Este `ledger_tip_hash` es el hash de la *última entrada añadida* al `HISTORY.md`.

4.  **Verificación de la Cadena (`verifyChain`)**:
    -   Durante operaciones críticas (ej. `gov audit`, `gov takeover` en Base2), `antigravity_dpi` invoca a `IntegrityEngine.verifyChain` para el `HISTORY.md` de Base2.
    -   `verifyChain` recorre el `HISTORY.md` de Base2, recalculando los hashes de cada línea y comparándolos con el `PrevHash` de la línea siguiente.
    -   Finalmente, compara el hash de la última línea del `HISTORY.md` con el `ledger_tip_hash` anclado en el `session.lock` de Base2.

5.  **Detección de Manipulaciones**:
    -   Si `verifyChain` detecta una inconsistencia (hash no coincide, `PrevHash` incorrecto, o `ledger_tip_hash` no coincide), se emite una alerta crítica (`[FORENSIC-FAIL] Ruptura de cadena`) y la operación se aborta.
    -   Esto asegura que cualquier intento de modificar, insertar o eliminar entradas en el `HISTORY.md` de Base2 sea detectado.

## 5. Hardening y Seguridad

-   **Encadenamiento Criptográfico (VUL-11 Mitigado)**: Cada entrada está vinculada criptográficamente a la anterior mediante su hash, formando una cadena inmutable.
-   **Anclaje en `session.lock` (VUL-11 Mitigado)**: El `ledger_tip_hash` en el `session.lock` (protegido por HMAC) actúa como un ancla externa, previniendo la reescritura completa del historial.
-   **Bloqueo de Archivo (VUL-12 Mitigado)**: El `ForensicLedger` utiliza un mecanismo de bloqueo de archivo (`history.lock`) para evitar condiciones de carrera y asegurar que solo un proceso pueda escribir en el `HISTORY.md` a la vez, previniendo la corrupción del ledger.
-   **Determinismo de Hash**: El cálculo del hash de cada línea es determinista, asegurando que la verificación siempre produzca el mismo resultado para el mismo contenido.
-   **Self-Audit de `antigravity_dpi`**: La integridad del propio `ForensicLedger` de `antigravity_dpi` es verificada por el `Self-Audit`, garantizando que la herramienta que audita a Base2 es confiable.

## 6. Artefactos Relacionados (en el contexto de un proyecto Base2)

-   `base2_project/HISTORY.md`: El archivo de registro forense inmutable para el proyecto Base2.
-   `base2_project/session.lock`: Contiene el `ledger_tip_hash` y su HMAC.
-   `antigravity_dpi/lib/src/telemetry/forensic_ledger.dart`: Implementación del motor.
-   `antigravity_dpi/lib/src/security/integrity_engine.dart`: Implementación de la verificación de cadena.

## 7. Consideraciones Adicionales

-   **Rol y Atribución**: La inclusión del `Role` en cada entrada permite una atribución clara de las acciones, lo cual es vital para la responsabilidad y la auditoría.
-   **Granularidad del Detalle**: La `Detail` de cada entrada debe ser lo suficientemente descriptiva para proporcionar contexto sin ser excesivamente verbosa.
-   **Integración con Eventos de Base2**: Es crucial que los eventos clave del ciclo de vida de Base2 (ej. compilación, pruebas, despliegue) se integren para generar entradas en este `HISTORY.md` a través de `antigravity_dpi`.