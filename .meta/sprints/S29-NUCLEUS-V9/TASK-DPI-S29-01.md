# TASK-DPI-S29-01: Kernel Baseline v9.0.0 & Constant Verification

## Objetivo
Establecer el nuevo baseline generacional v9.0.0 e inyectar las constantes de seguridad para el motor determinista.

## Alcance Técnico
- Actualización de `version` en `backlog.json` y `pubspec.yaml` a **9.0.0-EVO**.
- Inyección de constantes de entorno/clase:
    - `CONTEXT_WINDOW = 500000`
    - `OUTPUT_LIMIT = 8192`
    - `T_OUT_WEIGHT = 1.5`
- Verificación de integridad inicial del núcleo pre-refactor.

## Criterios de Aceptación
1. `gov status` reportando versión 9.0.0.
2. Constantes accesibles desde `TelemetryService`.
3. Sello de ADN binario actualizado.

---
**Protocolo**: [DPI-GATE-GOLD]  
**Estado**: TODO
