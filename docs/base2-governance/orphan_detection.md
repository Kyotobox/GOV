# Detección de Archivos Huérfanos (Orphan Detection para Base2)

**Ruta del Módulo Core**: `lib/src/security/integrity_engine.dart` (dentro de `antigravity_dpi`)
**Nivel de Gobernanza**: GATE-GOLD

## 1. Resumen

La "Detección de Archivos Huérfanos" es un bloque de gobernanza implementado por `antigravity_dpi` (nuestro Control Plane) para los productos del ecosistema Base2. Su propósito es identificar cualquier archivo presente en los directorios de un proyecto Base2 que no esté explícitamente registrado en su manifiesto de integridad (`base2_manifest.hashes`) ni en una lista de exenciones conocidas. Este mecanismo es crucial para prevenir la inyección de código o artefactos no autorizados, manteniendo la superficie de ataque de Base2 lo más reducida posible.

## 2. Propósito

-   **Prevenir Inyección de Código**: Detectar la presencia de archivos no autorizados que podrían ser código malicioso, backdoors o componentes no aprobados.
-   **Mantener la Higiene del Proyecto**: Asegurar que los entornos de Base2 contengan solo los artefactos esperados y necesarios para su operación.
-   **Reforzar la Integridad del Manifiesto**: Complementar la verificación de hashes al asegurar que no hay "extras" que puedan eludir el control de versiones o la auditoría.
-   **Alertar sobre Desviaciones**: Notificar sobre cualquier desviación del estado esperado del sistema de archivos de Base2.

## 3. Componentes Involucrados (de `antigravity_dpi`)

Los siguientes módulos de `antigravity_dpi` colaboran para implementar este bloque de gobernanza en Base2:

-   **`IntegrityEngine` (`lib/src/security/integrity_engine.dart`)**: Contiene la función `detectOrphans` que realiza el escaneo de directorios y la comparación con el manifiesto de Base2.
-   **`Vault` (`vault/`)**: Almacenará el manifiesto de integridad (`base2_manifest.hashes`) firmado de Base2, que es la fuente de verdad contra la cual se comparan los archivos.
-   **CLI (`bin/antigravity_dpi.dart`)**: Orquesta la ejecución de la detección de huérfanos, ya sea como parte de una auditoría (`gov audit`) o como un comando independiente (`gov base2 detectOrphans`).
-   **`ForensicLedger` (`lib/src/telemetry/forensic_ledger.dart`)**: Registrará los eventos de detección de huérfanos en el `HISTORY.md` de `antigravity_dpi`, incluyendo la lista de archivos encontrados.

## 4. Flujo de Operación en el Ecosistema Base2

1.  **Carga del Manifiesto**: `antigravity_dpi` carga el `base2_manifest.hashes` (previamente firmado y verificado) del proyecto Base2. Este manifiesto contiene una lista de todos los archivos esperados y sus hashes.

2.  **Escaneo de Directorios**: `antigravity_dpi` escanea recursivamente los directorios relevantes del proyecto Base2 (ej. `bin/`, `lib/`, `config/`, `assets/`).

3.  **Comparación y Detección**:
    -   Para cada archivo encontrado durante el escaneo, `antigravity_dpi` verifica si su ruta relativa está presente como una clave en el `base2_manifest.hashes`.
    -   Si un archivo no se encuentra en el manifiesto, se considera un "huérfano".

4.  **Reporte de Huérfanos**:
    -   Si se detectan archivos huérfanos, `antigravity_dpi` los lista y emite una advertencia o un error crítico, dependiendo de la configuración de gobernanza de Base2.
    -   Este evento se registra en el `HISTORY.md` de `antigravity_dpi`.

## 5. Hardening y Seguridad

-   **Comparación Exacta (VUL-09 Mitigado)**: La lógica de `detectOrphans` utiliza una comparación exacta de rutas relativas para determinar si un archivo está en el manifiesto. Esto previene que archivos maliciosos con nombres similares a los legítimos (ej. `libpayload.dart` vs `lib/payload.dart`) evadan la detección.
-   **Normalización de Rutas**: Se utilizan funciones de normalización de rutas para asegurar que las comparaciones sean consistentes y no se vean afectadas por diferencias en la sintaxis de rutas entre sistemas operativos.
-   **Manifiesto Firmado**: La detección de huérfanos se basa en un manifiesto (`base2_manifest.hashes`) que ha sido previamente firmado con RSA, garantizando que la lista de archivos esperados no ha sido manipulada.
-   **Self-Audit de `antigravity_dpi`**: La integridad del propio `IntegrityEngine` de `antigravity_dpi` es verificada por el `Self-Audit`, garantizando que la herramienta que detecta huérfanos en Base2 es confiable.

## 6. Artefactos Relacionados (en el contexto de un proyecto Base2)

-   `base2_project/vault/base2_manifest.hashes`: El manifiesto de integridad firmado del proyecto Base2.
-   `base2_project/vault/base2_manifest.hashes.sig`: La firma RSA del manifiesto.
-   `antigravity_dpi/lib/src/security/integrity_engine.dart`: Implementación de la función `detectOrphans`.

## 7. Consideraciones Adicionales

-   **Exenciones Específicas de Base2**: Los proyectos Base2 pueden necesitar definir sus propias listas de exención para archivos generados en tiempo de ejecución o temporales que no deben ser considerados huérfanos. Estas exenciones deben ser gestionadas de forma segura y transparente.
-   **Integración en CI/CD**: La detección de huérfanos es más efectiva cuando se integra en los pipelines de CI/CD de Base2, ejecutándose automáticamente antes de cada despliegue.