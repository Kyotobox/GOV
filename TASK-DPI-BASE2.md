# TASK-DPI-BASE2: Protocolo de Integración y Pase a Producción (BASE2)

> [!IMPORTANT]
> **ESTADO DE PRE-REQUISITOS**:
> - [x] **S19-FORTRESS** (verificación de cadena criptográfica y tests unitarios) completado, validado y fusionado en el kernel.

## FASE 0: Deprecación del Esquema Legacy (PS/OPS)
1. **Limpieza de Scripts de Validación**: Identificar y eliminar todos los scripts de PowerShell (`.ps1`) y archivos de configuración `.ops` que gobernaban el esquema de validación anterior.
2. **Actualización de Entrypoints**: Modificar cualquier pipeline, archivo batch o acceso directo externo para que apunte exclusivamente al nuevo motor CLI (`dart bin/antigravity_dpi.dart` o su binario compilado).
3. **Validación de Ausencia Legacy**: Asegurar que ningún archivo `.ops` residual quede en el árbol de directorios protegido por el `GATE-GOLD`.

## FASE 1: Auditoría y Sellado Atómico
1. **Determinismo Unitario (Self-Audit)**: Ejecutar toda la suite de pruebas unitarias (`dart test test/`). Se debe garantizar que el 100% de las pruebas, especialmente las relativas al motor de integridad y criptografía (`verifyChain`, `verifyManifest`), pasen sin incidentes.
2. **Limpieza de Huérfanos**: Ejecutar el motor de integridad (`detectOrphans`) para rastrear y eliminar cualquier archivo residual o temporal en `bin/` o `lib/` que no deba pasar a producción.

## FASE 2: Sellado Criptográfico Definitivo (GATE-GOLD)
1. **Regeneración del Manifiesto**: Ejecutar la función `generateHashes` para actualizar el estado definitivo de cada archivo que compone el binario de producción.
2. **Firma RSA de Producción**: Utilizar la llave privada RSA de 2048 bits designada para producción para firmar el nuevo archivo `vault/kernel.hashes`, produciendo así el `vault/kernel.hashes.sig` inmutable.

## FASE 3: Protocolo de Relevo (Cierre Seguro)
1. **Congelamiento de Estado**: Ejecutar `gov handover` para anclar definitivamente el estado de la sesión pre-despliegue. Esto forzará una escritura sellada en `HISTORY.md` y un guardado del `ledger_tip_hash` en el archivo `session.lock` (con su HMAC respectivo).
2. **Validación del Relay**: Verificar que el Relay Atómico generado contenga la firma RSA del PO y el hash de Git que representa al candidato a *Release*.

## FASE 4: Fusión y Etiquetado Criptográfico (Git)
1. **Commit Final (Freeze)**: Consolidar todos los cambios del `vault` y asegurar que el árbol de trabajo (working tree) está completamente limpio.
2. **Git Tagging**: Aplicar la etiqueta de versión BASE2 (ej. `git tag -a BASE2-PROD -m "Release Producción BASE2"`).
3. **Push a SSoT**: Subir los cambios y las etiquetas al repositorio remoto.

## FASE 5: Verificación Post-Pase en Entorno Prod (Takeover Inicial)
1. **Clonado en Frío**: En el entorno destino o de validación final, realizar un clonado limpio apuntando a la etiqueta `BASE2-PROD`.
2. **Inicialización (Gov Takeover)**: El primer analista o sistema automatizado debe ejecutar `gov takeover`. 
3. **Criterio de Éxito**: Si el motor `GATE-GOLD` certifica la inmutabilidad del manifiesto, aprueba la firma RSA y valida todo el Ledger `HISTORY.md` retrospectivamente, **BASE2 se considera operativamente activo y seguro.**