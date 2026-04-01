# TASK-DPI-S27-01: AI-LOG-CRAWLER

## Descripción
Implementar en el `ContextEngine` del motor la capacidad de escanear proactivamente los logs de interacción (ej. `overview.txt`) para detectar la bandera `finish_reason: MAX_TOKENS`.

## Criterios de Aceptación
- El motor debe identificar cuando una respuesta ha sido truncada por límites del modelo.
- Se debe registrar el evento en el `ForensicLedger`.
- El estado de saturación debe reflejar la presión de salida.

## Estado
- [ ] Implementación de Scanner.
- [ ] Unit Test de detección.
- [ ] Integración con Pulse.
