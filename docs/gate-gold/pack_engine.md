# Motor de Empaquetado (PackEngine)

**Ruta**: `lib/src/core/pack_engine.dart` (lógica distribuida)
**Nivel de Gobernanza**: GATE-RED

## 1. Resumen

El `PackEngine` es el componente `GATE-RED` de `antigravity_dpi` responsable de generar paquetes de exportación (`audit_export_*.zip`) del proyecto. Su función es crear un archivo ZIP limpio y seguro que contenga el código fuente relevante para auditorías externas, excluyendo explícitamente información sensible o archivos irrelevantes para el proceso de revisión.

## 2. Propósito

-   **Facilitar Auditorías Externas**: Proporcionar un mecanismo estandarizado para exportar el código fuente a auditores externos o equipos de seguridad.
-   **Prevenir Fuga de Información (VUL-10 Mitigado)**: Asegurar que los paquetes de exportación no incluyan datos sensibles como claves privadas o manifiestos internos del `vault/`.
-   **Optimizar el Tamaño del Paquete**: Excluir directorios de build, herramientas y otros archivos no esenciales para reducir el tamaño del ZIP.
-   **Garantizar la Integridad del Contenido**: Asegurar que solo se empaqueten proyectos que hayan pasado una auditoría de integridad previa.

## 3. Componentes Involucrados

-   **`PackEngine` (lógica distribuida)**: La lógica para la creación del ZIP y el filtrado de archivos.
-   **`IntegrityEngine` (`lib/src/security/integrity_engine.dart`)**: Ejecuta una auditoría previa (`gov audit`) antes de cualquier empaquetado.
-   **`archive` (paquete externo)**: Biblioteca de Dart utilizada para el manejo de archivos ZIP.

## 4. Flujo de Operación (`gov pack`)

1.  **Auditoría Previa**: Antes de iniciar el empaquetado, `gov pack` invoca obligatoriamente a `gov audit`. Si la auditoría falla, el empaquetado se aborta.
2.  **Inicialización**: El `PackEngine` se inicializa con la ruta base del proyecto.
3.  **Filtrado de Archivos**: Escanea el árbol de directorios del proyecto, aplicando reglas de exclusión para directorios como `.git/`, `.dart_tool/`, `build/`, y el directorio `vault/`.
4.  **Creación del ZIP**: Utiliza el paquete `archive` para añadir los archivos filtrados al archivo `audit_export.zip`.
5.  **Generación de `audit_export.zip`**: El archivo ZIP resultante se guarda en la raíz del proyecto.

## 5. Hardening y Seguridad

-   **Exclusión Explícita de `vault/` (VUL-10 Mitigado)**: El `PackEngine` excluye explícitamente el directorio `vault/` de los paquetes de exportación, previniendo la fuga de información sensible (claves, manifiestos) a auditores externos o entornos no controlados.
-   **Auditoría Previa Obligatoria**: La ejecución de `gov audit` antes del empaquetado asegura que solo se exporten proyectos que cumplan con los estándares de integridad.
-   **Protección contra Zip Slip (VUL-14 Mitigado)**: Se utilizan funciones de normalización de rutas (`p.normalize`) para prevenir ataques de Zip Slip, asegurando que los archivos no puedan escapar del directorio de destino al descomprimir.

## 6. Artefactos Relacionados

-   `audit_export.zip`: El archivo ZIP generado que contiene el código fuente para auditoría.
-   `vault/`: Directorio excluido del empaquetado.
-   `TASK-DPI-S10-02.md`: Documento de tarea que describe la implementación inicial de `gov pack`.