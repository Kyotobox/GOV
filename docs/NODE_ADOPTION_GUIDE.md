# Guía de Adopción de Nodos Independientes (v9.0.1)

Esta guía instruye a los responsables locales de los proyectos externos (`Base2`, `miniduo`) sobre cómo integrar las actualizaciones de gobernanza emitidas por el núcleo central manteniendo su autonomía operativa.

## 1. Filosofía de Independencia
Cada búnker es el único soberano de su propio código fuente y llaves privadas (`po_private.xml`). La integración con el oráculo `antigravity_dpi` es un acto de suscripción voluntaria para obtener certificación de integridad y telemetría avanzada.

## 2. Recepción de Candidatos
El Kernel central depositará en tu carpeta `bin/` los siguientes archivos:
- `gov.exe.update`: El nuevo motor de gobernanza.
- `gov.exe.update.sig`: La firma digital RSA del motor.
- `vanguard.exe.update`: La nueva interfaz de agente.
- `vanguard.exe.update.sig`: La firma digital RSA de la interfaz.

## 3. Fase de Verificación y Auditoría
Antes de aplicar la actualización, verifique el estado pendiente:
- **Comando**: `.\bin\gov.exe audit`
- **Acción**: El sistema detectará los archivos `.update` pero informará que la versión activa sigue siendo la anterior.

## 3. Ejecución del Hot-Swap (Upgrade)
Para aplicar el cambio de forma segura y certificada:
- **Comando**: `.\bin\gov.exe upgrade`
- **Lo que sucede**:
  1. El sistema verifica las firmas RSA usando tu `vault/po_public.xml` local.
  2. Si la firma es válida, renombra el binario actual a `.old` (Backup).
  3. Sustituye el binario por la versión `.update`.

## 4. Validación Final
Tras el upgrade, certifique que el nuevo motor está operativo:
- **Comando**: `.\bin\gov.exe status`
- **Resultado**: Debería ver la versión `v9.0.1` (NUCLEUS-V9) activa.

## 5. Protocolo de Rollback
Si la nueva versión presenta inestabilidad:
1. Elimine el `.exe` actual.
2. Renombre el `.exe.old` de vuelta a `.exe`.
3. Reporte el incidente al núcleo central.

> [!IMPORTANT]
> **SEGURIDAD ATÓMICA**: El comando `upgrade` fallará con un error crítico si la firma RSA no coincide. Nunca intente renombrar los archivos manualmente; esto invalidará la cadena de custodia del ADN binario.
