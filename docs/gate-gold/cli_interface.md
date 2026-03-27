# Interfaz de Línea de Comandos (CLI)

**Ruta**: `bin/antigravity_dpi.dart`
**Nivel de Gobernanza**: GATE-RED

## 1. Resumen

La Interfaz de Línea de Comandos (CLI) es el punto de entrada único (`gov.exe`) para todas las operaciones de gobernanza de `antigravity_dpi`. Actúa como el orquestador principal, interpretando los comandos del usuario, invocando los módulos internos apropiados y gestionando la interacción con el entorno. Es la cara visible del motor de gobernanza, diseñada para ser robusta, segura y eficiente.

## 2. Propósito

-   **Punto de Entrada Unificado**: Proporcionar una única interfaz para interactuar con todas las funcionalidades de `antigravity_dpi`.
-   **Orquestación de Comandos**: Dirigir las solicitudes del usuario a los módulos de gobernanza (`GATE-GOLD` y `GATE-RED`) correspondientes.
-   **Gestión de Interacción**: Manejar la entrada de usuario, la salida de información y los mensajes de error.
-   **Validación Previa**: Realizar verificaciones iniciales (ej. `Self-Audit`) antes de ejecutar cualquier comando.

## 3. Componentes Involucrados

-   **`bin/antigravity_dpi.dart`**: El archivo principal que contiene la lógica de parseo de comandos y la orquestación.
-   **Todos los módulos `GATE-GOLD` y `GATE-RED`**: Son invocados por la CLI para realizar sus funciones específicas.

## 4. Flujo de Operación

1.  **`Self-Audit Obligatorio`**: Antes de cualquier operación, la CLI invoca al `IntegrityEngine` para verificar la integridad de su propio binario (`verifySelf`). Si falla, el motor se niega a operar.
2.  **Parseo de Comandos**: La CLI analiza los argumentos de línea de comandos para identificar el comando y sus opciones.
3.  **Orquestación**: Invoca la función o el módulo adecuado para ejecutar la lógica del comando solicitado (ej. `runAudit`, `runBaseline`, `runHandover`).
4.  **Salida**: Muestra los resultados de la operación, mensajes de estado o errores al usuario.

## 5. Hardening y Seguridad
-   **Self-Audit Obligatorio**: Garantiza que la propia herramienta de gobernanza no ha sido comprometida antes de ejecutar cualquier comando.
-   **Mecanismo Anti-Loop (S16-03)**: Implementa un límite de tasa para las invocaciones de la CLI, previniendo ataques de denegación de servicio o bucles accidentales.
-   **Registro Forense**: Todas las operaciones significativas ejecutadas a través de la CLI se registran en el `HISTORY.md`.

## 6. Artefactos Relacionados
-   `COMMANDS.md`: Documentación de todos los comandos disponibles.
-   `HISTORY.md`: Registro inmutable de las operaciones de gobernanza.