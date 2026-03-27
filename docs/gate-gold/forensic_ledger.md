# Registro Forense (ForensicLedger)

**Ruta**: `lib/src/telemetry/forensic_ledger.dart`
**Nivel de Gobernanza**: GATE-GOLD

## 1. Resumen

El `ForensicLedger` es el componente responsable de mantener un registro inmutable y auditable de todas las acciones significativas realizadas dentro del sistema `antigravity_dpi`. Opera como una cadena de bloques simplificada, donde cada entrada (log) se encadena criptográficamente a la anterior mediante un hash SHA-256, garantizando la integridad del historial y haciendo que cualquier alteración sea matemáticamente detectable.

## 2. Responsabilidades Clave

- **Registro Inmutable**: Añade nuevas entradas al archivo `HISTORY.md`, calculando el hash de la entrada anterior y de la nueva para formar una cadena criptográfica.
- **Anclaje de la Cadena**: El hash de la última entrada (`ledger_tip_hash`) se ancla en el `session.lock`, que a su vez está protegido por un HMAC, previniendo la reescritura de la cadena desde cero.
- **Protección contra Race Conditions**: Implementa un mecanismo de bloqueo (mutex) para asegurar que solo una operación de escritura pueda acceder al `HISTORY.md` a la vez, evitando la corrupción del registro por concurrencia.
- **Verificación de Integridad**: Permite verificar la cadena de hashes del `HISTORY.md` para detectar cualquier manipulación.

## 3. Flujo de Operación

1.  **Inicialización**: Al inicio de una sesión, el `ForensicLedger` carga el `HISTORY.md` existente y verifica la cadena de hashes hasta el `ledger_tip_hash` anclado en `session.lock`.
2.  **Registro de Eventos**: Cuando ocurre un evento significativo (ej. `baseline`, `handover`, `takeover`, `audit`), el `ForensicLedger` realiza lo siguiente:
    -   Obtiene el hash de la última línea del `HISTORY.md`.
    -   Calcula el hash de la nueva entrada, incluyendo el hash de la línea anterior.
    -   Añade la nueva entrada al `HISTORY.md` bajo un bloqueo de archivo.
    -   Actualiza el `ledger_tip_hash` en `session.lock` con el hash de la nueva entrada.

## 4. Mejoras de Hardening (Sprint S13)

De acuerdo con el `backlog.json`, las vulnerabilidades de Prioridad 2 identificadas en la auditoría fueron mitigadas en el sprint `S13-IMMUTABILITY`:

-   **Falsa Inmutabilidad (VUL-11 Mitigado)**: Anteriormente, la cadena de `HISTORY.md` podía ser reescrita desde cero si un atacante manipulaba el archivo. *Mitigación:* Ahora, el `ledger_tip_hash` (el hash de la última entrada del historial) se ancla en el `session.lock`. Dado que el `session.lock` está protegido por un HMAC (`VUL-16` mitigado en S11), cualquier intento de reescribir el historial sin actualizar el ancla y su HMAC resultará en una falla de integridad crítica.
-   **Race Condition de Logs (VUL-12 Mitigado)**: La ejecución concurrente de operaciones de registro podía corromper el `HISTORY.md`. *Mitigación:* Se implementó un mecanismo de bloqueo de archivo (mutex) al hacer `append` al `HISTORY.md`, asegurando que las escrituras sean atómicas y secuenciales.

## 5. Artefactos y Dependencias Relacionadas

-   `HISTORY.md`: El archivo principal donde se registran todos los eventos.
-   `session.lock`: Almacena el `ledger_tip_hash` anclado y su HMAC, crucial para la verificación de la inmutabilidad.
-   `IntegrityEngine`: Utiliza el `ForensicLedger` para verificar la integridad del historial como parte de la auditoría general.
-   `package:crypto`: Utilizado para el cálculo de hashes SHA-256.
-   `package:path`: Para la gestión de rutas de archivos.

## 6. Verificación de la Cadena

El `ForensicLedger` proporciona funciones para verificar la integridad de la cadena de `HISTORY.md` en cualquier momento. Un fallo en esta verificación indica una posible manipulación del historial, lo que activaría una alerta crítica en el sistema de gobernanza.