# Motor de Integridad Criptográfica (GATE-GOLD para Base2)

**Ruta del Módulo Core**: `lib/src/security/integrity_engine.dart` (dentro de `antigravity_dpi`)
**Nivel de Gobernanza**: GATE-GOLD

## 1. Resumen

El "Motor de Integridad Criptográfica" es el pilar fundamental de la gobernanza que `antigravity_dpi` (nuestro Control Plane) extiende al ecosistema Base2. Su función es asegurar la autenticidad e inmutabilidad de todos los binarios, artefactos y configuraciones desplegadas en los productos Base2. Mediante el uso de hashes criptográficos (SHA-256) y firmas digitales RSA, `antigravity_dpi` garantiza que el software en producción es exactamente el que fue aprobado y certificado, detectando cualquier alteración no autorizada de forma inmediata.

## 2. Propósito

-   **Autenticidad del Software**: Certificar que el código y los artefactos de Base2 provienen de una fuente autorizada y no han sido falsificados.
-   **Inmutabilidad del Despliegue**: Asegurar que una vez que un componente de Base2 ha sido desplegado y certificado, no puede ser modificado sin que `antigravity_dpi` detecte una violación.
-   **Detección Temprana de Manipulaciones**: Identificar cualquier intento de alteración (accidental o maliciosa) en el entorno de producción de Base2, desde el código fuente hasta los binarios compilados y archivos de configuración.
-   **Fuente de Verdad Confiable**: Establecer un manifiesto firmado como la única fuente de verdad sobre el estado esperado de los artefactos de Base2.

## 3. Componentes Involucrados (de `antigravity_dpi`)

Los siguientes módulos de `antigravity_dpi` colaboran para implementar este bloque de gobernanza en Base2:

-   **`IntegrityEngine` (`lib/src/security/integrity_engine.dart`)**: Es el motor principal que genera los hashes de los archivos de Base2, construye el manifiesto de integridad y realiza la verificación de los hashes y la firma del manifiesto.
-   **`SignEngine` (`lib/src/security/sign_engine.dart`)**: Proporciona las capacidades criptográficas de firma y verificación RSA, utilizadas por el `IntegrityEngine` para sellar y validar los manifiestos de Base2.
-   **`VanguardCore` (`lib/src/security/vanguard_core.dart`)**: Puede ser invocado para emitir desafíos de alta severidad (`GATE-BLACK`) si se detectan violaciones críticas de integridad en Base2.
-   **`Vault` (`vault/`)**: Almacenará los manifiestos de integridad (`base2_manifest.hashes`), sus firmas (`base2_manifest.hashes.sig`) y las claves públicas RSA necesarias para verificar los artefactos de Base2.
-   **`ForensicLedger` (`lib/src/telemetry/forensic_ledger.dart`)**: Registrará todos los eventos de generación, firma y verificación de manifiestos de Base2 en el `HISTORY.md` de `antigravity_dpi`, proporcionando una pista de auditoría inmutable.

## 4. Flujo de Operación en el Ecosistema Base2

1.  **Generación del Manifiesto de Base2**:
    -   Un proceso automatizado (ej. CI/CD de Base2) o un comando `gov` específico (ej. `gov base2 manifest generate --path /ruta/a/base2/proyecto`) invoca a `antigravity_dpi`.
    -   `antigravity_dpi` utiliza su `IntegrityEngine` para escanear los directorios designados del proyecto Base2 (ej. `bin/`, `lib/`, `config/`) y generar un archivo de manifiesto (`base2_manifest.hashes`) con los hashes SHA-256 de todos los artefactos relevantes.

2.  **Firma del Manifiesto de Base2**:
    -   Una vez generado el manifiesto, `antigravity_dpi` (a través de su `IntegrityEngine` y `SignEngine`) lo firma digitalmente utilizando una clave privada RSA de producción específica para Base2.
    -   Esto produce un archivo de firma (`base2_manifest.hashes.sig`) que acompaña al manifiesto. Este paso requiere la aprobación del Product Owner (PO) o un sistema de gestión de claves seguro.

3.  **Despliegue y Verificación en Runtime/CI/CD**:
    -   Antes de cada despliegue de Base2, o como parte de una verificación continua en runtime, `antigravity_dpi` es invocado para auditar el entorno de Base2.
    -   `antigravity_dpi` lee el `base2_manifest.hashes` y su `base2_manifest.hashes.sig` del entorno de Base2.
    -   Utiliza la clave pública RSA correspondiente (almacenada en el `Vault` de `antigravity_dpi` o accesible de forma segura) para verificar la firma del manifiesto.
    -   Si la firma es válida, `antigravity_dpi` procede a recalcular los hashes de los artefactos desplegados en Base2 y los compara con los hashes registrados en el manifiesto.

4.  **Detección y Respuesta a Anomalías**:
    -   Si la firma del manifiesto es inválida o si algún hash de artefacto no coincide, `antigravity_dpi` emitirá una alerta crítica (`[CRITICAL] KERNEL-VIOLATION` o similar), deteniendo el despliegue o marcando el entorno como comprometido.
    -   Estos eventos se registrarán en el `HISTORY.md` de `antigravity_dpi` y, si la severidad lo amerita, podrían escalar a un `GATE-BLACK`.

## 5. Hardening y Seguridad

-   **Criptografía de Grado Militar**: Utiliza algoritmos SHA-256 para hashing y RSA-2048 para firmas, proporcionando una base criptográfica robusta.
-   **Separación de Responsabilidades**: `antigravity_dpi` actúa como un verificador externo e independiente para Base2, evitando que Base2 se auto-certifique.
-   **Gestión Segura de Claves**: Las claves RSA de producción para Base2 serán gestionadas de forma segura, idealmente fuera del repositorio de Base2 y accesibles solo por `antigravity_dpi` bajo estrictos controles.
-   **Inmutabilidad del Manifiesto**: La firma RSA del manifiesto de Base2 garantiza que cualquier modificación en el manifiesto sea detectable, protegiendo la fuente de verdad.
-   **Self-Audit de `antigravity_dpi`**: La propia `antigravity_dpi` se somete a un `Self-Audit Obligatorio` antes de cada operación, asegurando que el Control Plane que audita a Base2 es, a su vez, íntegro y no ha sido comprometido.

## 6. Artefactos Relacionados (en el contexto de un proyecto Base2)

-   `base2_project/vault/base2_manifest.hashes`: Archivo JSON con los hashes SHA-256 de los artefactos de Base2.
-   `base2_project/vault/base2_manifest.hashes.sig`: Firma RSA del manifiesto de Base2.
-   `base2_project/vault/base2_po_public.xml`: Clave pública RSA utilizada para verificar la firma del manifiesto de Base2.
-   `antigravity_dpi/HISTORY.md`: Registro forense de `antigravity_dpi` que incluye eventos de gobernanza de Base2.

## 7. Consideraciones Adicionales

-   **Integración con CI/CD**: La efectividad de este bloque de gobernanza se maximiza cuando se integra directamente en los pipelines de CI/CD de Base2, forzando la verificación de integridad antes de cualquier despliegue.
-   **Granularidad del Manifiesto**: La definición de qué archivos se incluyen en el manifiesto de Base2 es crucial. Debe ser lo suficientemente granular para detectar cambios significativos, pero no tan excesiva que genere ruido o sobrecarga.
-   **Rotación de Claves**: Se debe establecer un protocolo para la rotación periódica de las claves RSA de producción utilizadas para firmar los manifiestos de Base2.