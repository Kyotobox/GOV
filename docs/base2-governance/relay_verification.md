# Verificación de Relevos (Relay Verification para Base2)

**Ruta del Módulo Core**: `lib/src/security/vanguard_core.dart` (dentro de `antigravity_dpi`)
**Nivel de Gobernanza**: GATE-GOLD

## 1. Resumen

La "Verificación de Relevos" es un bloque de gobernanza crucial que `antigravity_dpi` (nuestro Control Plane) aplica a los productos del ecosistema Base2. Su propósito es asegurar que cualquier despliegue o cambio significativo en Base2 se origine de un estado conocido, sellado y autorizado. Esto se logra mediante la validación del `git_hash` del código fuente y la firma RSA del "Relay Atómico" asociado a la operación. Este proceso garantiza que solo las versiones de código certificadas y aprobadas puedan transicionar a entornos de producción o etapas críticas del ciclo de vida de Base2.

## 2. Propósito

-   **Control de Origen Certificado**: Asegurar que el código desplegado en Base2 proviene de un commit específico y autorizado en el repositorio de control de versiones.
-   **Prevención de Desviaciones (`Git-Drift`)**: Detectar cualquier discrepancia entre el estado del repositorio de Base2 en el momento de la operación y el `git_hash` registrado en el Relay Atómico.
-   **Autorización del Product Owner (PO)**: Requerir la firma RSA del PO para certificar la aprobación de la operación, vinculando la responsabilidad directamente a una entidad humana.
-   **Continuidad de la Cadena de Confianza**: Extender la cadena de confianza desde el `handover` de `antigravity_dpi` hasta las operaciones en Base2.

## 3. Componentes Involucrados (de `antigravity_dpi`)

Los siguientes módulos de `antigravity_dpi` colaboran para implementar este bloque de gobernanza en Base2:

-   **`VanguardCore` (`lib/src/security/vanguard_core.dart`)**: Es el motor principal para la emisión y verificación de desafíos (`issueChallenge`, `waitForSignature`). Genera los desafíos que requieren la firma del PO para las operaciones de Base2.
-   **`SignEngine` (`lib/src/security/sign_engine.dart`)**: Proporciona las capacidades criptográficas de verificación RSA, utilizadas por `VanguardCore` para validar las firmas de los Relays Atómicos de Base2.
-   **`IntegrityEngine` (`lib/src/security/integrity_engine.dart`)**: Utilizado para verificar la integridad del `session.lock` de Base2, que puede contener el `git_hash` del último estado sellado.
-   **CLI (`bin/antigravity_dpi.dart`)**: Orquesta los comandos que inician y validan los procesos de relevo en Base2 (ej. `gov base2 deploy --relay <relay_id>`).
-   **`ForensicLedger` (`lib/src/telemetry/forensic_ledger.dart`)**: Registrará los eventos de verificación de relevos en el `HISTORY.md` de `antigravity_dpi`, incluyendo el `git_hash` y el resultado de la verificación.

## 4. Flujo de Operación en el Ecosistema Base2

1.  **Generación del Relay Atómico**:
    -   Antes de una operación crítica en Base2 (ej. despliegue a producción), `antigravity_dpi` genera un "Relay Atómico". Este Relay es un desafío que incluye el `git_hash` del código a desplegar y otros metadatos relevantes.
    -   `VanguardCore` emite este desafío, que requiere la firma RSA del PO.

2.  **Firma del Relay por el PO**:
    -   El Product Owner (PO) recibe el desafío y lo firma digitalmente utilizando su clave privada RSA, generando un archivo de firma (`signature.json`).

3.  **Inicio de Operación en Base2**:
    -   Cuando se inicia la operación en Base2 (ej. `gov base2 deploy`), `antigravity_dpi` recibe el Relay Atómico firmado.
    -   `antigravity_dpi` extrae el `git_hash` del Relay y el `git_hash` actual del repositorio de Base2.

4.  **Verificación del `git_hash`**:
    -   `antigravity_dpi` compara el `git_hash` del Relay con el `git_hash` actual del repositorio de Base2.
    -   Si no coinciden (`GIT-DRIFT`), la operación se aborta con una alerta crítica.

5.  **Verificación de la Firma RSA**:
    -   `antigravity_dpi` utiliza `VanguardCore.waitForSignature` y `SignEngine` para verificar la autenticidad de la firma RSA del Relay Atómico utilizando la clave pública del PO.
    -   Si la firma es inválida, la operación se aborta con una alerta crítica.

6.  **Registro y Continuación**:
    -   Si todas las verificaciones son exitosas, `antigravity_dpi` registra el evento en su `HISTORY.md` y permite que la operación en Base2 continúe.

## 5. Hardening y Seguridad

-   **`GIT-DRIFT` Prevention**: La comparación estricta del `git_hash` previene el despliegue de código no autorizado o no versionado.
-   **Firma RSA Obligatoria**: La firma del PO en el Relay Atómico proporciona una prueba irrefutable de autorización y atribución.
-   **Replay Protection (VUL-25)**: El `VanguardCore` elimina el archivo `signature.json` después de su uso, previniendo ataques de re-uso de firmas.
-   **Self-Audit de `antigravity_dpi`**: La integridad de `antigravity_dpi` se verifica antes de cada operación, asegurando que el Control Plane que valida los relevos de Base2 es confiable.

## 6. Artefactos Relacionados (en el contexto de un proyecto Base2)

-   `base2_project/.git/HEAD`: Referencia al commit actual del repositorio de Base2.
-   `base2_project/vault/intel/challenge.json`: Desafío emitido por `antigravity_dpi` para la operación de Base2.
-   `base2_project/vault/intel/signature.json`: Firma RSA del PO para el desafío.
-   `antigravity_dpi/HISTORY.md`: Registro forense de `antigravity_dpi` que incluye eventos de verificación de relevos de Base2.