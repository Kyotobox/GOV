# Motor de Empaquetado (PackEngine)

**Ruta**: `lib/src/core/pack_engine.dart`
**Nivel de Gobernanza**: GATE-RED

## 1. Resumen

El `PackEngine` es el componente `GATE-RED` responsable de generar paquetes de exportación (`.zip`) del proyecto para propósitos de auditoría externa. Su función es asegurar que el paquete contenga todo el código fuente relevante y los artefactos de gobernanza, excluyendo información sensible o directorios temporales. Este proceso es crítico para la transparencia y la verificación por parte de terceros, garantizando que la versión auditada sea una representación fiel del estado del kernel.

## 2. Responsabilidades Clave

- **Generación de Archivos ZIP**: Crea un archivo comprimido que incluye los directorios y archivos especificados.
- **Filtrado Inteligente de Archivos**: Incluye selectivamente el código fuente (`lib/src/`) y los artefactos de gobernanza, mientras excluye directorios sensibles como `vault/` y archivos temporales.
- **Protección contra Zip Slip**: Normaliza y verifica las rutas de los archivos para prevenir ataques de Path Traversal durante la descompresión.
- **Integración con Auditoría**: Requiere una auditoría previa (`gov audit`) para asegurar la integridad del proyecto antes de empaquetar.

## 3. Flujo de Operación (`gov pack`)

1.  **Auditoría Previa**: Antes de iniciar el empaquetado, se ejecuta una auditoría completa del sistema (`runAudit`). Si la auditoría falla, el proceso de empaquetado se aborta para evitar exportar un estado comprometido.
2.  **Selección de Archivos**: El `PackEngine` define una lista de directorios y archivos a incluir, como `bin/`, `lib/src/`, `pubspec.yaml`, `pubspec.lock`, `VISION.md`, `GEMINI.md`, `backlog.json`, `HISTORY.md`, `DASHBOARD.md` y `TASK-DPI-*.md`.
3.  **Exclusión de Archivos Sensibles**: Excluye explícitamente el directorio `vault/` (que contiene claves y manifiestos sensibles) y otros archivos temporales o de configuración local.
4.  **Compresión**: Los archivos seleccionados se añaden al archivo ZIP.
5.  **Registro Forense**: Una vez completado el empaquetado, se registra una entrada `SNAP | PACK` en el `HISTORY.md`, detallando el nombre del archivo ZIP generado.

## 4. Hardening y Seguridad

El `PackEngine` ha sido objeto de mejoras significativas para abordar vulnerabilidades críticas:

-   **Fuga de Información (VUL-10 Mitigado)**: Anteriormente, el `PackEngine` incluía todo el directorio `vault/`, exponiendo claves privadas y manifiestos de hashes. *Mitigación (Sprint S11-HOTFIX):* Se implementó una lógica de filtrado explícita para excluir el directorio `vault/` del paquete de exportación, asegurando que los secretos no salgan del entorno controlado.
-   **Ocultamiento de Código (VUL-13 Mitigado)**: El `PackEngine` fallaba al incluir módulos críticos del kernel en el ZIP. *Mitigación (Sprint S11-HOTFIX):* Se revisó y actualizó la lista de inclusión para garantizar que todos los archivos `.dart` dentro de `lib/src/` sean empaquetados, asegurando una auditoría completa del código fuente.
-   **Zip Slip (VUL-14 Mitigado)**: Existía el riesgo de que archivos con rutas manipuladas (`../`) pudieran sobrescribir archivos fuera del directorio de destino al descomprimir el ZIP. *Mitigación (Sprint S13-IMMUTABILITY):* Se implementó una normalización robusta de rutas utilizando `p.normalize` y `p.isWithin` del paquete `path` durante el proceso de adición de archivos al ZIP. Esto previene que rutas maliciosas puedan escapar del directorio raíz del paquete.

## 5. Integración con Otros Módulos

-   **CLI (`bin/antigravity_dpi.dart`)**: Invoca el `PackEngine` a través del comando `gov pack`.
-   **`IntegrityEngine`**: Se ejecuta una auditoría completa antes del empaquetado para garantizar la integridad del proyecto.
-   **`ForensicLedger`**: Registra el evento de empaquetado en el `HISTORY.md`.

## 6. Artefactos Relacionados

-   `audit_export_*.zip`: Archivos ZIP generados por el `PackEngine`.
-   `vault/`: Directorio excluido del empaquetado.
-   `lib/src/`: Directorio principal de código fuente incluido.

## 7. Consideraciones Adicionales

La efectividad del `PackEngine` depende de la precisión de sus reglas de inclusión y exclusión. Cualquier cambio en la estructura del proyecto o la adición de nuevos tipos de artefactos sensibles debe ir acompañado de una revisión de la configuración del `PackEngine` para mantener la seguridad y la completitud de los paquetes de auditoría.