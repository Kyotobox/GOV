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
2.  **Cálculo de Telemetría y Aprobación del PO**:
    - El `TelemetryService` calcula el `System Health Score (SHS)` de la sesión.
    - El `VanguardCore` emite un desafío de nivel `TACTICAL`, solicitando una firma del PO para autorizar el cierre de sesión.
    - Si la firma no es validada, el `handover` se aborta.
4.  **Sellado del `session.lock`**:
    - Se captura el hash corto del commit de Git (`git rev-parse --short HEAD`).
    - El archivo `session.lock` se actualiza con:
        - `status`: `HANDOVER_SEALED`
        - `shs_at_close`: El valor de saturación del SHS, que se convertirá en la fatiga heredada.
        - `git_hash`: El hash de Git capturado.
    - Se genera un nuevo HMAC (`_mac`) para proteger la integridad del archivo.
5.  **Registro en el `HISTORY.md`**:
    - Se añade una entrada al `HISTORY.md` que registra el evento de `handover`, incluyendo el SHS y el hash de Git.

### 4.2. Takeover (Reanudación de Sesión)

1.  **Pre-condiciones**:
    - Debe existir un archivo `session.lock` con estado `HANDOVER_SEALED`.
2.  **Validación de Integridad**:
    - Se verifica la integridad del `session.lock` validando su HMAC (`_mac`).
    - Se compara el `git_hash` almacenado en el `session.lock` con el hash del `HEAD` actual del repositorio para prevenir `GIT-DRIFT`.
    - Se ejecuta una auditoría completa (`gov audit`) del sistema.
4.  **Actualización del `session.lock`**:
    - El archivo `session.lock` se actualiza con el estado `IN_PROGRESS`, un nuevo `timestamp` y el valor de `inherited_fatigue` (que se toma del `shs_at_close` de la sesión anterior).
    - Se genera un nuevo HMAC (`_mac`).
5.  **Registro en el `HISTORY.md`**:
    - Se añade una entrada al `HISTORY.md` que registra el evento de `takeover`, incluyendo el valor de `inherited_fatigue`.

## 5. Diagrama de Flujo (Opcional)

[Incluir un diagrama de flujo que visualice el proceso de Handover/Takeover]

## 6. Consideraciones de Seguridad