# TASK-DPI-S29-02: Hot-Capture Interceptor & sessionLog Persistence

## Objetivo
Implementar la captura directa de metadatos de tokens desde la respuesta de la API y asegurar su persistencia atómica en el `sessionLog`.

## Alcance Técnico
- Método `updateMetadata(promptTokens, outputTokens, finishReason)` en `TelemetryService`.
- Creación de `vault/intel/session_log.json` (Array de objetos).
- Intercepción de `response.usageMetadata` para alimentar el motor de telemetría.
- Gestión de Memoria: Limpieza diferida del log vinculada al éxito de `triggerAutoHandover()`.

## Criterios de Aceptación
1. Registro de logs por cada turno verificado.
2. Persistencia post-recarga confirmada.
3. El log no se borra si el handover falla.

---
**Protocolo**: [DPI-GATE-GOLD]  
**Estado**: TODO
