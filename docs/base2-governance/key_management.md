# Gestión y Rotación de Claves RSA (para Base2)

**Ruta del Módulo Core**: `lib/src/security/key_generator.dart` (dentro de `antigravity_dpi`)
**Nivel de Gobernanza**: GATE-GOLD

## 1. Resumen

La gestión de claves RSA es un pilar fundamental para la seguridad y la gobernanza criptográfica en el ecosistema Base2, orquestada por `antigravity_dpi`. Este proceso abarca la generación, vinculación, rotación y almacenamiento seguro de pares de claves RSA (pública y privada) utilizadas para firmar manifiestos de integridad, autorizar operaciones críticas y verificar la identidad del Product Owner (PO). Una gestión robusta de estas claves es esencial para mantener la inmutabilidad y la confianza en el kernel de Base2.

## 2. Propósito

-   **Asegurar la Autenticidad**: Garantizar que los manifiestos de integridad (`kernel.hashes`) y las autorizaciones provienen de una fuente confiable (el PO).
-   **Garantizar la Inmutabilidad**: Proteger los artefactos críticos de Base2 contra manipulaciones no autorizadas mediante firmas digitales.
-   **Facilitar la Rotación Segura**: Proporcionar un mecanismo controlado para la actualización periódica de las claves, minimizando el riesgo de compromiso a largo plazo.
-   **Centralizar la Gestión**: Ofrecer una interfaz unificada (`gov vault`) para todas las operaciones relacionadas con las claves RSA.

## 3. Componentes Involucrados (de `antigravity_dpi`)

Los siguientes módulos de `antigravity_dpi` colaboran para implementar este bloque de gobernanza en Base2:

-   **`KeyGenerator` (`lib/src/security/key_generator.dart`)**: Responsable de generar nuevos pares de claves RSA (2048-bit) en formato XML.
-   **`IntegrityEngine` (`lib/src/security/integrity_engine.dart`)**: Utiliza las claves públicas para verificar las firmas de manifiestos y las claves privadas para generarlas.
-   **`VanguardCore` (`lib/src/security/vanguard_core.dart`)**: Emite desafíos que requieren la firma del PO, utilizando las claves RSA.
-   **CLI (`bin/antigravity_dpi.dart`)**: Orquesta los comandos `gov vault bind-key` y `gov vault rotate-keys` para la interacción del usuario.
-   **`ForensicLedger` (`lib/src/telemetry/forensic_ledger.dart`)**: Registra eventos de rotación y vinculación de claves en el `HISTORY.md`.

## 4. Flujo de Operación

### 4.1. Generación de Claves (`gov vault rotate-keys`)

1.  El comando `gov vault rotate-keys` invoca al `KeyGenerator`.
2.  Se genera un nuevo par de claves RSA de 2048 bits (pública y privada).
3.  Las claves existentes (`po_private.xml`, `po_public.xml`) en `vault/` se respaldan automáticamente.
4.  Las nuevas claves se guardan en `vault/po_private.xml` y `vault/po_public.xml`.
5.  Se registra un evento en el `HISTORY.md`.

### 4.2. Vinculación de Claves (`gov vault bind-key`)

1.  El comando `gov vault bind-key --project <ID> --key <PATH>` permite asociar una clave privada RSA específica a un ID de proyecto o sprint.
2.  La ruta a la clave se almacena en `vault/keys.json`. Esto permite que `antigravity_dpi` resuelva la clave correcta para diferentes contextos.
3.  Se registra un evento en el `HISTORY.md`.

### 4.3. Uso de Claves

-   **`baseline`**: Durante el `baseline`, `IntegrityEngine` utiliza la clave privada del PO (resolviendo su ruta desde `vault/keys.json` o `vault/po_private.xml`) para firmar `kernel.hashes`.
-   **`audit`**: Durante el `audit`, `IntegrityEngine` utiliza la clave pública del PO (resolviendo su ruta desde `vault/keys.json` o `vault/po_public.xml`) para verificar la firma de `kernel.hashes.sig`.
-   **`handover` / `baseline` (Aprobación PO)**: `VanguardCore` emite un desafío que el PO debe firmar con su clave privada. La verificación se realiza con la clave pública del PO.

## 5. Hardening y Seguridad

-   **Almacenamiento en `vault/`**: Todas las claves se almacenan en el directorio `vault/`, que está excluido de los paquetes de auditoría (`gov pack`) y se espera que tenga permisos de sistema de archivos restringidos.
-   **Formato XML**: Las claves se almacenan en formato XML, un estándar para la representación de claves RSA.
-   **Respaldo Automático**: La rotación de claves incluye un respaldo automático de las claves antiguas para recuperación en caso de error.
-   **Vinculación Segura (VUL-02 Mitigado)**: El mecanismo `bind-key` evita la exposición de rutas de claves en la línea de comandos o en configuraciones no seguras.
-   **Separación de Claves**: Se mantiene una distinción clara entre claves públicas (distribuibles) y privadas (altamente sensibles).
-   **Registro Forense**: Todas las operaciones de gestión de claves se registran en el `HISTORY.md`, proporcionando una pista de auditoría inmutable.

## 6. Artefactos Relacionados (en el contexto de un proyecto Base2)

-   `base2_project/vault/po_private.xml`: Clave privada RSA del PO.
-   `base2_project/vault/po_public.xml`: Clave pública RSA del PO.
-   `base2_project/vault/keys.json`: Mapeo de IDs de proyecto/sprint a rutas de claves privadas.
-   `antigravity_dpi/lib/src/security/key_generator.dart`: Implementación de la generación de claves.
-   `antigravity_dpi/bin/antigravity_dpi.dart`: CLI para los comandos `gov vault`.

## 7. Consideraciones Adicionales

-   **Protección de `po_private.xml`**: La clave privada del PO es el activo más crítico. Debe protegerse con el máximo rigor, idealmente con cifrado a nivel de sistema de archivos o en un HSM.
-   **Políticas de Rotación**: Se recomienda establecer políticas de rotación de claves regulares para mitigar el riesgo de compromiso a largo plazo.