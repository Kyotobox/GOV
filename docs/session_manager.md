# Gestión de Sesiones (SessionManager)

**Ruta**: `lib/src/core/session_manager.dart` (no existe como tal, lógica distribuida)
**Nivel de Gobernanza**: GATE-RED

## 1. Resumen

A diferencia de otros módulos, el `SessionManager` no es una clase o archivo único, sino una *función lógica* distribuida a través de varios componentes `GATE-RED` que coordinan el ciclo de vida de las sesiones de trabajo. Esto incluye el inicio, la continuación (`takeover`), el cierre (`handover`) y la invalidación de sesiones. La piedra angular de este subsistema es el archivo `session.lock`, que actúa como un candado atómico que controla el acceso al kernel y registra el estado de la sesión.

## 2. Responsabilidades Clave

- **Creación y Actualización de `session.lock`**: Almacena el estado de la sesión (`status`, `timestamp`, `inherited_fatigue`) y un hash MAC para verificar la integridad del archivo.
- **Implementación de Protocolos `handover` / `takeover`**: Coordina la transferencia de control entre analistas, validando firmas y registrando el relevo en el `HISTORY.md`.
- **Detección de Sesiones Zombie**: Implementa un "kill-switch" que invalida sesiones que han excedido un límite de tiempo, previniendo el bloqueo indefinido del kernel.
- **Persistencia de Estado**: Asegura que la fatiga cognitiva (`inherited_fatigue`) se transfiera correctamente entre sesiones, manteniendo la continuidad de la telemetría.

## 3. Componentes Involucrados

- **CLI (`bin/antigravity_dpi.dart`)**: Invoca las funciones de `handover` y `takeover`, gestionando el flujo general del ciclo de vida de la sesión.
- **`IntegrityEngine`**: Verifica la integridad del `session.lock` y la validez de las firmas RSA durante el `takeover`.
- **`TelemetryService`**: Calcula el pulso cognitivo y persiste el valor de fatiga heredada en el `session.lock`.
- **`ForensicLedger`**: Registra todos los eventos relacionados con la gestión de sesiones en el `HISTORY.md`.
- **`VanguardCore`**: Emite y valida los desafíos criptográficos que aseguran la autorización para las operaciones de `handover` y `takeover`.

## 4. Flujo de Operación

1.  **Inicio de Sesión (Implícito)**: La creación o modificación del `session.lock` con estado `IN_PROGRESS` marca el inicio de una sesión.
2.  **`handover`**:
    -   Verifica la integridad del sistema (`gov audit`).
    -   Calcula el pulso cognitivo y obtiene la firma RSA del `VanguardCore`.
    -   Sella el `session.lock` con estado `HANDOVER_SEALED`, incluyendo el hash del Git y la firma.
    -   Persiste el estado y la fatiga para la siguiente sesión.
3.  **`takeover`**:
    -   Verifica que la sesión anterior fue cerrada correctamente (`HANDOVER_SEALED`).
    -   Valida el hash de Git y la firma RSA del `VanguardCore`.
    -   Reanuda la sesión, actualizando el `session.lock` con estado `IN_PROGRESS` y la fatiga heredada.

## 5. Hardening y Seguridad

El `SessionManager` contribuye a la seguridad al:

- **Prevenir la Toma de Posesión No Autorizada**: Requiere la validación de firmas RSA y la verificación de la integridad del `session.lock` antes de permitir un `takeover`.
- **Implementar un "Kill-Switch"**: Invalida sesiones que han excedido un límite de tiempo, previniendo el bloqueo indefinido del kernel.
- **Asegurar la Continuidad de la Telemetría**: Persiste la fatiga cognitiva entre sesiones, proporcionando una visión precisa del estado del equipo.

## 6. Artefactos Relacionados

-   `session.lock`: El archivo central que controla el ciclo de vida de la sesión y almacena el estado.
-   `HISTORY.md`: Registra todos los eventos relacionados con la gestión de sesiones.
-   `VanguardCore`: Proporciona la infraestructura para la firma y verificación de los desafíos criptográficos.

## 7. Consideraciones Adicionales

Aunque el `SessionManager` no existe como un archivo `.dart` separado, la lógica distribuida que lo compone es esencial para la seguridad y la integridad del sistema. Futuras iteraciones podrían considerar la consolidación de esta lógica en un componente más cohesivo para mejorar la mantenibilidad y la auditabilidad.