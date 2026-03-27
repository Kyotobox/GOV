# Motor de Integridad (IntegrityEngine)

**Ruta**: `lib/src/security/integrity_engine.dart`
**Nivel de Gobernanza**: GATE-GOLD

## 1. Resumen

El `IntegrityEngine` es el pilar fundamental de la confianza en el ecosistema `antigravity_dpi`. Su única y crítica responsabilidad es garantizar que el código fuente del proyecto y el propio motor de gobernanza no han sido alterados. Actúa como un notario digital inmutable, comparando el estado actual de los archivos contra una "verdad" previamente registrada y firmada criptográficamente.

## 2. Responsabilidades Clave

- **Verificación de Manifiestos**: Valida que el manifiesto de hashes (`kernel.hashes`) no ha sido manipulado, verificando su firma RSA (`kernel.hashes.sig`).
- **Auditoría de Integridad del Kernel**: Calcula el hash SHA-256 de cada archivo crítico del proyecto y lo compara con el valor esperado en el manifiesto.
- **Detección de Archivos Huérfanos**: Identifica cualquier archivo presente en el árbol de directorios que no esté registrado en el manifiesto ni en la lista de exenciones, previniendo la inyección de código malicioso.
- **Auto-Auditoría (Self-Audit)**: Antes de ejecutar cualquier comando, el motor verifica la integridad de su propio binario compilado para asegurar que no está operando desde un estado corrupto.

## 3. Flujo de Verificación Detallado (`gov audit`)

El proceso de auditoría es secuencial y riguroso. Un fallo en cualquiera de los primeros pasos invalida inmediatamente todo el proceso.

1.  **Paso 1: Verificación de la Firma del Manifiesto**
    - El motor busca el archivo `vault/kernel.hashes.sig`.
    - Utilizando el `SignEngine`, verifica que esta firma sea válida y corresponda al contenido de `vault/kernel.hashes`.
    - **Mitigación (VUL-08)**: Este paso es crucial. Sin él, un atacante podría modificar `kernel.hashes` para que coincida con su código malicioso, envenenando la fuente de verdad. La firma RSA previene esto.

2.  **Paso 2: Carga del Manifiesto de Integridad**
    - Una vez verificada la firma, el motor lee el contenido de `vault/kernel.hashes` en memoria. Este archivo contiene un mapa de `[ruta_del_archivo]: [hash_sha256_esperado]`.

3.  **Paso 3: Cálculo y Comparación de Hashes**
    - El motor itera sobre cada archivo listado en el manifiesto.
    - Lee el contenido del archivo en el disco y calcula su hash SHA-256 actual.
    - Compara el hash calculado con el hash esperado del manifiesto. Si no coinciden, la auditoría falla con un error de `INTEGRITY_MISMATCH`.

4.  **Paso 4: Detección de Huérfanos**
    - El motor escanea el árbol de directorios del proyecto.
    - Compara la lista de archivos encontrados con la lista del manifiesto y una lista interna de exenciones (ej. `.git`, `build/`).
    - Si un archivo no está en ninguna de las dos listas, se reporta como un `ORPHAN_FILE`, y la auditoría falla.
    - **Mitigación (VUL-09)**: La lógica de comparación fue endurecida para usar una comparación exacta de rutas en lugar de `startsWith`, evitando que archivos maliciosos como `libpayload.dart` pudieran evadir la detección.

## 4. Auto-Auditoría del Binario (`verifySelf`)

Invocada al inicio de la ejecución de `gov.exe`, esta función realiza una auditoría de integridad sobre los archivos que componen el propio motor de gobernanza. Este mecanismo de "pre-vuelo" asegura que si el `gov.exe` es modificado, se negará a operar, terminando la ejecución con un código de salida `exit(2)`.

## 5. Artefactos Relacionados

-   `vault/kernel.hashes`: El manifiesto de verdad. Un archivo de texto plano que mapea rutas de archivos a sus hashes SHA-256.
-   `vault/kernel.hashes.sig`: La firma RSA del archivo `kernel.hashes`, que garantiza su autenticidad e integridad.