# El Archivo `session.lock`

## 1. Resumen

El `session.lock` es un archivo JSON ubicado en la raíz del proyecto que actúa como el **candado atómico** del kernel de `antigravity_dpi`. Es el punto de control central para la gestión del ciclo de vida de las sesiones de trabajo, la persistencia del estado y la garantía de integridad entre relevos (`handover`/`takeover`). Su existencia y contenido son críticos para la operación segura y continua del sistema.

## 2. Propósito

El `session.lock` cumple múltiples propósitos esenciales:

-   **Control de Acceso al Kernel**: Su presencia y estado (`IN_PROGRESS`, `HANDOVER_SEALED`, `BASELINE_SEALED`) determinan si el kernel está disponible para operaciones o si requiere una acción específica (ej. `takeover`).
-   **Persistencia de Estado de Sesión**: Almacena información vital sobre la sesión actual, como el `timestamp` de inicio, el `inherited_fatigue` y el `git_hash` del último estado sellado.
-   **Anclaje de Integridad**: Sirve como ancla criptográfica para el `ForensicLedger` (`ledger_tip_hash`) y para la verificación de la integridad del propio archivo mediante un HMAC (`_mac`).
-   **Mecanismo de Relevo**: Facilita el protocolo `handover`/`takeover` al encapsular el estado necesario para una transferencia de sesión segura y certificada.
-   **Detección de Sesiones Zombie (Kill-Switch)**: Su `timestamp` se utiliza para detectar y alertar sobre sesiones inactivas que exceden un límite de tiempo (8 horas), activando un "kill-switch" preventivo que bloquea operaciones hasta que se fuerce un `handover`.

## 3. Estructura del Archivo

El `session.lock` es un archivo JSON con la siguiente estructura (ejemplo):

```json
{
  "status": "IN_PROGRESS",
  "timestamp": "2026-03-27T02:03:38.218238",
  "inherited_fatigue": 2.0,
  "_mac": "17d1e9444d4c6dccd88e76abec2b80b520ba90d4bbeb0d3c97dcd029cf3ba8c7",
  "ledger_tip_hash": "f2982bf215848cc52dfdfd8b55966d746286b604ec3999b1d05dccf49ff65771",
  "sprint_id": "S15-SYMBIOSIS",
  "git_hash": "2cb4217",
  "shs_at_close": 54.0
}
```

**Campos Clave**:
-   `status` (String): Estado actual de la sesión (`IN_PROGRESS`, `HANDOVER_SEALED`, `BASELINE_SEALED`).
-   `timestamp` (String): Marca de tiempo ISO 8601 de la última actualización de estado.
-   `inherited_fatigue` (Double): Valor acumulado del Pulso Cognitivo (CP) heredado de sesiones anteriores.
-   `_mac` (String): Hash-based Message Authentication Code (HMAC) SHA-256 del contenido del archivo (excluyendo `_mac` mismo), garantizando su integridad.
-   `ledger_tip_hash` (String): Hash SHA-256 de la última entrada válida en `HISTORY.md`, anclando el registro forense.
-   `sprint_id` (String, opcional): ID del sprint activo en el momento del sellado.
-   `git_hash` (String, opcional): Hash corto del último commit de Git en el momento del sellado.
-   `shs_at_close` (Double, opcional): System Health Score (SHS) al momento del `handover`.

## 4. Ciclo de Vida y Flujo de Operación

1.  **Inicio Implícito**: La primera vez que se ejecuta un comando `gov` en un proyecto sin `session.lock`, se crea con `status: IN_PROGRESS`.
2.  **`handover`**: El `session.lock` se actualiza a `HANDOVER_SEALED`, registrando `shs_at_close`, `git_hash` y el `inherited_fatigue` para la próxima sesión. Se genera un nuevo `_mac`.
3.  **`takeover`**: Verifica el `session.lock` sellado, valida el `_mac` y el `git_hash`. Si es válido, lo actualiza a `IN_PROGRESS`, transfiriendo el `inherited_fatigue`. Se genera un nuevo `_mac`.
4.  **`baseline`**: El `session.lock` se actualiza a `BASELINE_SEALED`, registrando el `sprint_id` y el `git_hash` del sellado. Se genera un nuevo `_mac`.
5.  **Actualizaciones Continuas**: Durante la operación normal, el `IntegrityEngine` actualiza el `ledger_tip_hash` y el `_mac` cada vez que se añade una entrada al `HISTORY.md`.

## 5. Mecanismos de Seguridad

-   **HMAC (`_mac`) (VUL-16 Mitigado)**: Este es el mecanismo de seguridad más crítico del `session.lock`. Un HMAC SHA-256 se calcula sobre el resto del contenido del archivo y se almacena. Cualquier intento de modificar el `session.lock` sin recalcular el HMAC resultará en una falla de integridad detectada por el `IntegrityEngine`, abortando cualquier operación.
-   **Anclaje del Ledger (`ledger_tip_hash`) (VUL-11 Mitigado)**: Almacenar el hash de la última entrada del `HISTORY.md` en el `session.lock` (protegido por HMAC) previene la reescritura del historial. Si el `HISTORY.md` es manipulado, su hash no coincidirá con el ancla, activando una alerta crítica.
-   **Verificación de `git_hash`**: Durante el `takeover`, se compara el `git_hash` registrado en el `session.lock` con el `HEAD` actual del repositorio. Esto previene la reanudación de una sesión en un estado de código inconsistente.
-   **Kill-Switch de Sesiones Zombie (S16-02)**: El `timestamp` se utiliza durante la auditoría para invalidar sesiones que han estado `IN_PROGRESS` por un tiempo excesivo (ej. 8 horas), forzando un `handover --force` para liberar el kernel y prevenir bloqueos indefinidos.

## 6. Componentes que Interactúan con `session.lock`

-   **`IntegrityEngine`**: Lee y verifica el `_mac` y el `ledger_tip_hash`. Escribe el `ledger_tip_hash` y recalcula el `_mac`.
-   **`TelemetryService`**: Lee y escribe `inherited_fatigue`.
-   **`CLI` (`gov.exe`)**: Orquesta las operaciones de `handover`, `takeover`, `baseline` y `status`, que leen y escriben en `session.lock`.
-   **`ForensicLedger`**: Invoca al `IntegrityEngine` para actualizar el `ledger_tip_hash` en `session.lock`.

## 7. Consideraciones Adicionales

La robustez del `session.lock` es directamente proporcional a la seguridad de las claves RSA utilizadas para firmar los `baselines` y los desafíos de `handover`/`takeover`. Un compromiso de estas claves podría permitir la falsificación del `session.lock` y, por extensión, del estado de gobernanza del proyecto.