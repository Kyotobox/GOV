# [PROTOCOLO] Flujo de Decisión y Firma del Product Owner (v9.0.1)

Este documento define el procedimiento estándar para que el Product Owner (PO) ejerza su autoridad de mando e integridad sobre los nodos del ecosistema.

## 1. Fase de Observación (Oracle)
Antes de tomar cualquier decisión, el PO debe consultar el estado de la flota desde el Kernel (`antigravity_dpi`).
- **Comando**: `gov fleet-pulse`
- **Artefacto**: `docs/reports/FLEET_SCENARIO_V9.md` (Generado por la IA).

## 2. Fase de Selección y Auditoría
La gestión de la flota es **Descentralizada**. El PO debe "entrar" físicamente en el nodo que desea gestionar.
1. Cambiar al directorio del proyecto (p.ej. `cd Base2`).
2. Ejecutar Auditoría de Integridad: `gov audit`.
3. Revisar el `Pulse` local para identificar saturación o fallos de ADN.

## 3. Fase de Certificación (Firma RSA)
Para aprobar cambios o cerrar un ciclo de trabajo, el PO debe generar un **Sello de Verdad**.
- **Comando**: `gov baseline`
- **Mecánica**: El motor busca `vault/po_private.xml`. Solo si la firma RSA es válida, el estado del proyecto se marca como **SEALED**.
- **Efecto**: Cualquier modificación posterior del código sin una nueva firma invalidará el binario y activará el **SECURITY_HOLD**.

## 4. Fase de Relevo (Handover)
Para finalizar la sesión y persistir la telemetría:
- **Comando**: `gov handover`
- **Mecánica**: Genera un `session.relay` firmado. Es el único método autorizado para "pasar la posta" a la siguiente instancia de la IA o al siguiente analista analítico.

## 5. Resumen de Botones Tácticos

| Comando | Acción del PO | Rol de la IA |
| :--- | :--- | :--- |
| `gov status` | Consulta de saturación local. | Reporte de métricas. |
| `gov audit` | Validación de integridad. | Alertas de intrusión. |
| `gov baseline` | **Firma y Sello de Verdad**. | Generación de manifiesto. |
| `gov handover` | **Certificación de Sesión**. | Empaquetado de contexto. |
| `gov purge` | Limpieza de emergencia. | Ejecución técnica. |

> [!CAUTION]
> **SEGURIDAD ATÓMICA**: Nunca comparta su `po_private.xml`. Sin este archivo, la gobernanza entra en modo Lectura/Auditoría únicamente, bloqueando cualquier commit al Kernel.
