# Interfaz de Línea de Comandos (CLI)

**Ruta**: `bin/antigravity_dpi.dart` (ejecutable `gov.exe`)
**Nivel de Gobernanza**: GATE-RED

## 1. Resumen

La Interfaz de Línea de Comandos (CLI), implementada a través del binario `gov.exe`, es el punto de entrada único y centralizado para todas las operaciones de gobernanza del ecosistema `antigravity_dpi`. Actúa como el orquestador principal, interpretando los comandos del usuario y delegando la ejecución a los módulos internos correspondientes. Su diseño se adhiere estrictamente a la "Cerca Eléctrica" de `VISION.md` de **no incluir lógica de UI**, enfocándose puramente en la interacción por consola.

## 2. Responsabilidades Clave

- **Parseo de Argumentos**: Interpreta los comandos y opciones proporcionados por el usuario utilizando la librería `package:args`.
- **Auto-Auditoría Inicial**: Antes de procesar cualquier comando, invoca al `IntegrityEngine` para realizar un `Self-Audit` del propio binario (`verifySelf`), asegurando que no ha sido alterado.
- **Orquestación de Comandos**: Dirige la ejecución a las funciones específicas (`runAudit`, `runAct`, `runBaseline`, etc.) según el comando ingresado.
- **Gestión de Rutas Base**: Normaliza y gestiona la ruta base del proyecto (`basePath`) para asegurar que todas las operaciones se realicen en el contexto correcto.
- **Manejo de Errores Críticos**: Captura y reporta errores inesperados, terminando la ejecución de forma segura cuando la integridad del sistema está comprometida.

## 3. Flujo de Ejecución Principal (`main` function)

1.  **Verificación de Integridad del Binario**:
    -   `integrityEngine.verifySelf()` se ejecuta.
    -   Si falla, imprime un mensaje crítico y `exit(2)`.
2.  **Configuración del Parser de Argumentos**:
    -   Define los comandos principales (`audit`, `act`, `baseline`, `handover`, `takeover`, `status`, `context`, `vault`, `pack`) y sus opciones.
3.  **Parseo de la Entrada del Usuario**:
    -   Intenta parsear los argumentos de la línea de comandos.
    -   En caso de error de parseo, imprime un mensaje y termina.
4.  **Determinación del Comando**:
    -   Identifica el comando principal a ejecutar. Si no se especifica, muestra la ayuda y termina.
5.  **Despacho de Comandos**:
    -   Utiliza una estructura `switch` para invocar la función `run*` asíncrona correspondiente al comando.
    -   Cada función `run*` encapsula la lógica específica del comando y su interacción con otros módulos de gobernanza.

## 4. Comandos Principales

-   `gov audit`: Ejecuta una auditoría completa de integridad del proyecto.
-   `gov act`: Realiza una "acción" que incluye auditoría, cálculo de telemetría y registro en el historial.
-   `gov baseline`: Sella formalmente el kernel del proyecto, generando y firmando un nuevo manifiesto de hashes.
-   `gov handover`: Cierra una sesión de trabajo, registrando el estado y la fatiga para el siguiente relevo.
-   `gov takeover`: Recupera una sesión de trabajo, validando la continuidad y el estado heredado.
-   `gov status`: Muestra el estado actual del proyecto, incluyendo métricas de telemetría.
-   `gov context`: Genera un archivo de contexto focalizado para la IA.
-   `gov vault`: Gestiona las claves criptográficas vinculadas a proyectos.
-   `gov pack`: Exporta el proyecto a un archivo ZIP para auditorías externas.

## 5. Integración con Otros Módulos

La CLI interactúa directamente con la mayoría de los módulos de gobernanza:

-   `IntegrityEngine`: Para `Self-Audit`, `audit`, `baseline`, `handover`, `takeover`.
-   `TelemetryService`: Para `act`, `status`, `handover`, `takeover`.
-   `BacklogManager`: Para `act`, `handover`, `takeover`, `context`.
-   `ComplianceGuard`: Para `audit` (verificación de scope).
-   `ForensicLedger`: Para registrar eventos de `act`, `baseline`, `handover`, `takeover`, `pack`, `context`.
-   `VanguardCore`: Para `handover` (gestión de desafíos y firmas).
-   `PackEngine`: Para `pack`.
-   `ContextEngine`: Para `context`.

## 6. Artefactos Relacionados

-   `bin/antigravity_dpi.dart`: Código fuente principal del CLI.
-   `pubspec.yaml`: Define las dependencias, incluyendo `package:args`.
-   `session.lock`: Archivo de estado de sesión, leído y escrito por varios comandos.
-   `vault/keys.json`: Almacena las rutas de las claves vinculadas para el comando `vault`.

## 7. Hardening y Seguridad

La CLI incorpora mecanismos de seguridad como el `Self-Audit` al inicio y la validación de firmas en operaciones críticas (`baseline`, `handover`, `takeover`) para asegurar que solo se ejecuten comandos en un entorno confiable y con la autoridad adecuada.