# Protocolo de Relevos (Handover / Takeover)

## 1. Resumen

El protocolo de relevos (`handover` / `takeover`) es el mecanismo central para la gestión de sesiones de trabajo en el ecosistema `antigravity_dpi`. A diferencia de un simple cierre y apertura de sesión, el relevo asegura la *continuidad certificada* del trabajo, transfiriendo el estado del sistema, la fatiga cognitiva del equipo y la autorización de las operaciones. Este documento detalla el flujo completo del protocolo, los componentes involucrados, las validaciones y los posibles puntos de fallo.

## 2. Objetivos del Protocolo

- **Garantizar la Continuidad**: Transferir el estado del sistema (archivos modificados, configuraciones) entre sesiones sin pérdida de información.
- **Preservar la Integridad**: Validar que la sesión anterior fue cerrada correctamente y que no ha habido manipulación del estado.
- **Transferir la Fatiga Cognitiva**: Persistir y transferir el valor de `inherited_fatigue` para mantener la continuidad de la telemetría y evitar el agotamiento del equipo.
- **Establecer la Autoridad**: Asegurar que solo usuarios autorizados puedan reanudar o invalidar una sesión.

## 3. Componentes Involucrados

- **CLI (`bin/antigravity_dpi.dart`)**: Orquesta el flujo general del protocolo, invocando las funciones de los otros componentes.
- **`BacklogManager`**: Proporciona el contexto de la tarea activa y el sprint actual.
- **`IntegrityEngine`**: Verifica la integridad del `session.lock`, la validez de las firmas RSA y la consistencia del hash de Git.
- **`TelemetryService`**: Calcula el pulso cognitivo y persiste el valor de fatiga heredada en el `session.lock`.
- **`ForensicLedger`**: Registra todos los eventos relacionados con el relevo en el `HISTORY.md`.
- **`VanguardCore`**: Emite y valida los desafíos criptográficos que aseguran la autorización para las operaciones de `handover` y `takeover`.
- **`DashboardEngine`**: (Opcional) Actualiza el `DASHBOARD.md` con el estado de la nueva sesión.

## 4. Flujo de Operación Detallado

### 4.1. Handover (Cierre de Sesión)

1.  **Pre-condiciones**:
    - El sistema debe estar en un estado íntegro (ejecutar `gov audit`).
    - Debe haber una tarea activa en progreso.
2.  **Cálculo de Telemetría**:
    - El `TelemetryService` calcula el `System Health Score (SHS)` y el `Cognitive Pulse (CP)` de la sesión actual.
3.  **Generación del Relay**:
    - Se crea un archivo de relevo (`session_relay.json`) que contiene:
        - El estado del sistema (archivos modificados, configuraciones).
        - El valor de `inherited_fatigue`.
        - El hash del último commit de Git.
        - Una firma RSA del Product Owner (PO) autorizando el relevo.
4.  **Sellado del `session.lock`**:
    - El archivo `session.lock` se actualiza con el estado `HANDOVER_SEALED` y se incluye el hash del `session_relay.json`.
5.  **Registro en el `HISTORY.md`**:
    - Se añade una entrada al `HISTORY.md` que registra el evento de `handover`, incluyendo el SHS, el hash de Git y la referencia al archivo de relevo.

### 4.2. Takeover (Reanudación de Sesión)

1.  **Pre-condiciones**:
    - Debe existir un archivo `session.lock` con estado `HANDOVER_SEALED`.
    - El usuario que intenta el `takeover` debe tener la autorización del PO (verificar la firma RSA en el `session_relay.json`).
2.  **Validación del Relay**:
    - Se verifica la integridad del `session_relay.json` comparando el hash almacenado en el `session.lock`.
    - Se valida la firma RSA del PO en el `session_relay.json`.
3.  **Reconstrucción del Estado**:
    - Se aplica el estado del sistema almacenado en el `session_relay.json` (restaurando archivos modificados, configuraciones, etc.).
4.  **Actualización del `session.lock`**:
    - El archivo `session.lock` se actualiza con el estado `IN_PROGRESS`, el nuevo timestamp y el valor de `inherited_fatigue` transferido del `session_relay.json`.
5.  **Registro en el `HISTORY.md`**:
    - Se añade una entrada al `HISTORY.md` que registra el evento de `takeover`, incluyendo la referencia al archivo de relevo y el valor de `inherited_fatigue`.

## 5. Diagrama de Flujo (Opcional)

[Incluir un diagrama de flujo que visualice el proceso de Handover/Takeover]

## 6. Consideraciones de Seguridad