# Protocolo de Sellado (Baseline)

## 1. Resumen

El protocolo de sellado (`baseline`) es una operación crítica `GATE-GOLD` que formaliza un hito en el desarrollo del proyecto `antigravity_dpi`. Su propósito es crear una instantánea inmutable y criptográficamente verificable del estado del kernel (código fuente y artefactos de gobernanza) en un momento dado. Este proceso implica una auditoría exhaustiva, la generación y firma de un nuevo manifiesto de integridad, y la aprobación explícita del Product Owner (PO) para cambios estratégicos.

## 2. Objetivos del Protocolo

- **Certificación de Hitos**: Marcar un punto de referencia estable y confiable en el historial del proyecto.
- **Inmutabilidad del Kernel**: Garantizar que el código fuente y los artefactos de gobernanza no han sido alterados desde el último `baseline`.
- **Trazabilidad y Auditoría**: Proporcionar un punto de verificación para auditorías externas y asegurar la trazabilidad de los cambios.
- **Autorización Formal**: Requerir la aprobación explícita del PO para sellar el kernel, elevando la seguridad a un nivel estratégico.

## 3. Componentes Involucrados

- **CLI (`bin/antigravity_dpi.dart`)**: Orquesta el flujo general del protocolo a través del comando `gov baseline`.
- **`IntegrityEngine`**: Responsable de generar los hashes de los archivos del kernel y de firmar/verificar el manifiesto de integridad (`kernel.hashes`).
- **`SignEngine`**: Realiza las operaciones criptográficas RSA de firma y verificación.
- **`BacklogManager`**: Proporciona el contexto del sprint y la tarea activa para el registro y el auto-commit semántico.
- **`VanguardCore`**: Gestiona el desafío de aprobación del PO para sellos estratégicos.
- **`ForensicLedger`**: Registra el evento de `baseline` en el `HISTORY.md`.
- **`TelemetryService`**: Calcula el pulso cognitivo para el momento del sellado.

## 4. Flujo de Operación Detallado (`gov baseline`)

El proceso de `baseline` es riguroso y secuencial, diseñado para asegurar la máxima integridad y autorización.

1.  **Auditoría Previa**:
    -   Se ejecuta una auditoría completa del sistema (`runAudit`), pero se omite la verificación de la firma del manifiesto (`skipSignatureCheck: true`) ya que el objetivo es precisamente generar una nueva firma.
    -   Si la auditoría detecta cualquier otra violación de integridad (archivos corruptos, huérfanos, etc.), el `baseline` se aborta.

2.  **Aprobación del Product Owner (PO)**:
    -   El sistema busca la clave pública del PO vinculada al proyecto (`_resolvePublicKey`).
    -   El `VanguardCore` emite un desafío de nivel `STRATEGIC-GOLD`, solicitando la firma del PO. Este paso es un "Human-in-the-Loop" (HITL) obligatorio para sellos estratégicos.
    -   El sistema espera una firma RSA válida del PO. Si no se recibe dentro de un tiempo límite o la firma es inválida, el `baseline` se aborta.

3.  **Resolución de Clave Privada**:
    -   Se resuelve la ruta a la clave privada RSA del PO, preferentemente desde el `vault/keys.json` vinculado al proyecto.

4.  **Captura del Hash de Git**:
    -   Se obtiene el hash corto del último commit de Git (`git rev-parse --short HEAD`) para anclar el `baseline` al historial de versiones.

5.  **Actualización del `session.lock`**:
    -   El archivo `session.lock` se actualiza con el estado `BASELINE_SEALED`, el timestamp, el ID del sprint y el hash de Git.
    -   Se genera y se añade un HMAC (`_mac`) al `session.lock` para proteger su integridad.

6.  **Generación y Firma del Manifiesto de Integridad**:
    -   El `IntegrityEngine` genera un nuevo `vault/kernel.hashes` que contiene los hashes SHA-256 de todos los archivos críticos del kernel.
    -   Las claves del manifiesto se ordenan alfabéticamente para asegurar un JSON determinista (mitigación de `VUL-08`).
    -   El `IntegrityEngine` utiliza el `SignEngine` para firmar criptográficamente el `kernel.hashes` con la clave privada del PO, creando `vault/kernel.hashes.sig`.

7.  **Auto-Commit Semántico (TASK-S16-01)**:
    -   Se realiza un `git add .` y un `git commit` automático.
    -   El mensaje del commit se genera semánticamente, incluyendo el ID del sprint y, si hay una tarea activa, su ID y descripción.

8.  **Registro Forense**:
    -   El `ForensicLedger` registra una entrada de tipo `BASE` en el `HISTORY.md`, detallando el `baseline` completado y el hash de Git.

## 5. Hardening y Seguridad

-   **Aprobación HITL (Human-in-the-Loop)**: La exigencia de una firma RSA del PO para sellos `STRATEGIC-GOLD` introduce una capa de seguridad humana, previniendo `baselines` no autorizados o malintencionados.
-   **Firma Criptográfica del Manifiesto (VUL-08 Mitigado)**: El `kernel.hashes.sig` asegura que el manifiesto de verdad no pueda ser alterado sin invalidar la firma, protegiendo la fuente de verdad del sistema.
-   **Integridad del `session.lock` (VUL-16 Mitigado)**: El HMAC en `session.lock` previene la manipulación del estado de sellado y del hash de Git asociado.
-   **Auto-Commit Semántico**: Aunque es una mejora operativa, el auto-commit asegura que cada `baseline` esté explícitamente registrado en el historial de versiones, mejorando la trazabilidad.

## 6. Artefactos Relacionados

-   `vault/kernel.hashes`: Manifiesto de hashes del kernel.
-   `vault/kernel.hashes.sig`: Firma RSA del manifiesto de hashes.
-   `session.lock`: Almacena el estado `BASELINE_SEALED` y el HMAC.
-   `HISTORY.md`: Registro inmutable de todos los eventos de `baseline`.
-   `vault/keys.json`: Almacena las rutas a las claves RSA del PO.
-   `.git/`: Repositorio de control de versiones.

## 7. Consideraciones Adicionales

El protocolo `baseline` es la máxima expresión de la gobernanza del proyecto. Su ejecución debe ser un acto deliberado y consciente, ya que establece un punto de no retorno para la integridad del kernel. Cualquier fallo en este proceso indica una violación crítica de la seguridad o la gobernanza.