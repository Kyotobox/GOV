# Gestión de Secretos (Vault)

**Ruta**: `lib/src/security/vault.dart` (lógica distribuida)
**Nivel de Gobernanza**: GATE-GOLD

## 1. Resumen

El `Vault` no es un componente monolítico, sino una función lógica distribuida a través de varios componentes `GATE-GOLD` que interactúan con un directorio central (`vault/`) para gestionar el acceso a secretos y artefactos criptográficos. Este subsistema asegura la confidencialidad, integridad y disponibilidad de los datos sensibles necesarios para la operación del sistema `antigravity_dpi`.

## 2. Responsabilidades Clave

- **Almacenamiento Seguro**: Persistencia de claves RSA, manifiestos de hashes (`kernel.hashes`) y otros datos sensibles en archivos protegidos dentro del directorio `vault/`.
- **Acceso Controlado**: Implementación de rutinas de carga y acceso a los secretos con validaciones criptográficas (ej. verificación de firmas RSA).
- **Generación de Contexto Focalizado**: Creación de un archivo `ai_context.txt` que contiene el alcance dinámico de la tarea actual (S15), permitiendo que la IA se enfoque en las áreas relevantes del proyecto.
- **Protección contra Manipulación**: Uso de HMAC y otros mecanismos para prevenir la alteración no autorizada de los datos almacenados.

## 3. Componentes Involucrados

- `IntegrityEngine`: Valida la integridad del `kernel.hashes` y otros manifiestos.
- `SignEngine`: Genera y verifica firmas RSA para proteger los secretos.
- `ForensicLedger`: Registra todas las acciones relacionadas con el acceso y la modificación de los secretos.
- `VanguardCore`: Gestiona la autorización y el control de acceso a los secretos.

## 4. Flujo de Operación

1.  **Inicialización**: Al inicio de una sesión, los componentes `GATE-GOLD` cargan los secretos necesarios desde el directorio `vault/`, verificando sus firmas y hashes.
2.  **Acceso a Secretos**: Los componentes utilizan los secretos para realizar sus funciones, como la firma de manifiestos o la verificación de la identidad de los usuarios.
3.  **Modificación de Secretos**: Cuando es necesario modificar un secreto (ej. al generar un nuevo manifiesto de hashes), el cambio se registra en el `ForensicLedger` y se protege con una firma RSA.

## 5. Hardening y Seguridad

El directorio `vault/` está protegido por varios mecanismos de seguridad, incluyendo:

-   **Control de acceso a nivel de sistema de archivos**: Solo los usuarios autorizados pueden acceder a los archivos dentro del directorio.
-   **Validación criptográfica**: Todos los artefactos críticos están protegidos con firmas RSA o hashes.
-   **Registro forense**: Todas las acciones relacionadas con el acceso y la modificación de los secretos se registran en el `ForensicLedger`.

## 6. Artefactos Relacionados

-   `vault/kernel.hashes`: Manifiesto de hashes de los archivos del sistema.
-   `vault/kernel.hashes.sig`: Firma RSA del manifiesto de hashes.
-   `vault/private_key.xml`: Clave privada RSA utilizada para firmar los manifiestos.
-   `vault/public_key.xml`: Clave pública RSA utilizada para verificar las firmas.
-   `vault/ai_context.txt`: Contexto focalizado para la IA (S15).