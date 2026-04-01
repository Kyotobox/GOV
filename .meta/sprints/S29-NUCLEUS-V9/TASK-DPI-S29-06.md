# TASK-DPI-S29-06: Security Hold & Critical Preservation Logic

## Objetivo
Implementar la detención automática de rutinas de escritura y limpieza ante fallas críticas de integridad binaria.

## Alcance Técnico
- Estado `SECURITY_HOLD` (BHI >= 90).
- Aborto de `resetCounters()` ante estado crítico.
- Bloqueo de escritura en `vault/` y `session.lock` (Software Gate).
- Protocolo `HUMAN_INTERVENTION`: Requisito de desbloqueo manual vía comando `gov vault unhold`.

## Criterios de Aceptación
1. El sistema no permite cambios en `vault/` si BHI es crítico.
2. La evidencia de la sesión se preserva intacta (Sin auto-limpieza).
3. Desbloqueo verificado con firma de Nivel PO/ARCH.

---
**Protocolo**: [DPI-GATE-GOLD]  
**Estado**: DONE
