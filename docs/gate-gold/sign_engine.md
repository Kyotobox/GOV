# Motor Criptográfico (SignEngine)

**Ruta**: `lib/src/security/sign_engine.dart`
**Nivel de Gobernanza**: GATE-GOLD

## 1. Resumen

El `SignEngine` es el núcleo de la confianza criptográfica del ecosistema `antigravity_dpi`. Su responsabilidad es gestionar todas las operaciones de firma asimétrica (RSA) y verificación. Asegura de manera determinista que cualquier cambio de estado crítico, delegación de autoridad (relevos) o artefacto de integridad (`kernel.hashes`) provenga de una entidad autorizada y no haya sido alterado en tránsito o en reposo.

## 2. Responsabilidades Clave

- **Generación de Firmas**: Sella criptográficamente desafíos (challenges) y manifiestos de integridad utilizando claves privadas RSA.
- **Verificación de Firmas**: Valida firmas entrantes utilizando claves públicas para autenticar acciones críticas (ej. `gov takeover`).
- **Parseo Seguro de Claves**: Procesa archivos de claves XML (estándar heredado/.NET) construyendo los parámetros matemáticos RSA necesarios para el motor interno.

## 3. Arquitectura y Evolución

El motor ha evolucionado hacia un modelo *Zero-Trust* nativo en el Sprint `S12-INTEGRITY`, eliminando la dependencia de scripts externos e implementando criptografía nativa y determinista.

- **Motor Base**: Utiliza implementaciones robustas de RSA (ej. `PointyCastle`) para aislar la criptografía dentro del binario compilado `gov.exe` (**VUL-SAFE-01** mitigado).
- **Parseo Determinista**: Las claves asimétricas en formato XML ahora son procesadas mediante un analizador de árbol de nodos nativo (`package:xml`), asegurando que no existan fallos de parseo por saltos de línea irregulares, una debilidad crítica previa basada en Regex (**VUL-01** mitigado).

## 4. Flujos Críticos Asociados

1.  **Firma del Manifiesto de Integridad**: El `IntegrityEngine` invoca al `SignEngine` para generar `vault/kernel.hashes.sig`. Sin esta validación criptográfica, el motor se negará a iniciar.
2.  **Validación de Continuidad (`Takeover`)**: Durante la toma de posesión, el motor verifica el relevo (relay) dejado por el analista saliente usando su firma RSA, garantizando la cadena de custodia ininterrumpida.

## 5. Mejoras de Hardening (Sprint S14)

De acuerdo con el `backlog.json`, las vulnerabilidades de Prioridad 3 identificadas en la auditoría fueron mitigadas en el sprint `S14-ERGONOMICS`:

-   **Gestión de Memoria y Zeroing (VUL-03 Mitigado)**: Se implementó una función `_zeroOut` que sobrescribe explícitamente con ceros los búferes de memoria que contienen componentes sensibles de las claves RSA (`Modulus`, `D`, `P`, `Q`, `Exponent`) inmediatamente después de su uso. Esto previene que datos criptográficos permanezcan en el heap, reduciendo la ventana de oportunidad para ataques de volcado de memoria.
-   **Manejo Estricto de Excepciones (VUL-04 Mitigado)**: Se refactorizó el manejo de errores. Las excepciones críticas durante el parseo de claves o la inicialización del motor ahora provocan un `rethrow`, deteniendo la ejecución de forma segura. Los fallos de verificación de firma son capturados de forma controlada, retornando `false` y registrando un mensaje de depuración en `stderr` sin detener el programa, diferenciando un ataque de un error del sistema.

## 6. Artefactos y Dependencias Relacionadas

-   `vault/`: Directorio central que alberga los repositorios de claves que este motor consume.
-   **Dependencias Externas**: `package:xml` (Parseo), Motor criptográfico (e.g., `PointyCastle` o equivalentes de encriptación).