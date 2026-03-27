# Motor Criptográfico (SignEngine)

**Ruta**: `lib/src/security/sign_engine.dart`
**Nivel de Gobernanza**: GATE-GOLD

## 1. Resumen

El `SignEngine` es el componente `GATE-GOLD` de `antigravity_dpi` encargado de gestionar todas las operaciones de firma y verificación RSA. Es el núcleo de la confianza para la validación de claves, sesiones y artefactos críticos, asegurando la autenticidad e integridad de los datos mediante el uso de criptografía de clave pública.

## 2. Propósito

-   **Autenticidad**: Certificar que un mensaje o un artefacto proviene de una fuente autorizada.
-   **Integridad**: Asegurar que un mensaje o un artefacto no ha sido alterado después de ser firmado.
-   **No Repudio**: Proporcionar una prueba irrefutable de que una entidad específica realizó una acción (ej. firmar un manifiesto).
-   **Gestión de Claves**: Facilitar el uso seguro de claves RSA públicas y privadas para operaciones criptográficas.

## 3. Componentes Involucrados

-   **`SignEngine` (`lib/src/security/sign_engine.dart`)**: La clase principal que implementa los métodos `sign` y `verify`.
-   **`pointycastle`**: Biblioteca criptográfica de Dart utilizada para las operaciones RSA y SHA-256.
-   **`package:xml`**: Utilizado para el parseo robusto de claves RSA en formato XML.

## 4. Flujo de Operación

1.  **Firma de un Desafío (`sign`)**:
    -   Recibe un `challenge` (datos a firmar) y una clave privada RSA en formato XML.
    -   Parsea la clave privada XML para extraer sus componentes (`Modulus`, `D`, `P`, `Q`).
    -   Utiliza `RSASigner` con `SHA256Digest` para generar una firma digital del desafío.
    -   **Mitigación (VUL-03)**: Se realiza un "zeroing" de los buffers sensibles después de su uso para evitar la exposición de datos en memoria.

2.  **Verificación de una Firma (`verify`)**:
    -   Recibe un `challenge`, una `signature` y una clave pública RSA en formato XML.
    -   Parsea la clave pública XML para extraer sus componentes (`Modulus`, `Exponent`).
    -   Utiliza `RSASigner` con `SHA256Digest` para verificar la firma contra el desafío.
    -   **Mitigación (VUL-04)**: Manejo específico de fallos de verificación versus errores del sistema, con logging detallado.

## 5. Hardening y Seguridad

-   **Parseo XML Robusto (VUL-01 Mitigado)**: Utiliza `package:xml` para parsear claves RSA en formato XML, mitigando la fragilidad de expresiones regulares.
-   **Fuerza de Clave (S19-FORTRESS)**: Impone una profundidad de bits mínima de 2048 bits para las claves RSA, asegurando un grado de seguridad FORTRESS.
-   **Zeroing de Datos Sensibles (VUL-03 Mitigado)**: Limpia la memoria de los buffers que contienen datos sensibles (claves, desafíos) después de su uso.
-   **Manejo de Errores (VUL-04 Mitigado)**: Proporciona un manejo de errores más granular y logging para fallos en la verificación o inicialización del motor.

## 6. Artefactos Relacionados

-   `vault/po_public.xml`: Clave pública RSA del Product Owner.
-   `vault/po_private.xml`: Clave privada RSA del Product Owner.
-   `lib/src/security/integrity_engine.dart`: Utiliza el `SignEngine` para firmar y verificar manifiestos.