# TASK-DPI-S19-01: Rotación de Claves a RSA-2048

**Estado**: PENDING
**Prioridad**: CRITICAL (GATE-GOLD)
**CP**: 15.0

## 1. Descripción
Elevar la muralla criptográfica del sistema mediante la generación de un nuevo par de claves RSA de 2048 bits, reemplazando la clave de desarrollo de 512 bits. Esto mitiga la posibilidad de ataques de fuerza bruta contra las firmas del kernel.

## 2. Alcance (Scope)
- `vault/po_private.xml` (Update)
- `vault/po_public.xml` (Update)
- `lib/src/security/sign_engine.dart` (Verification of bit-depth support)
- `bin/antigravity_dpi.dart` (Key migration logic)

## 3. Requerimientos Operativos
1. Generar nuevo par de claves RSA-2048.
2. Actualizar el Vault con las nuevas claves.
3. El sistema debe invalidar el `baseline` anterior y forzar un re-sellado con la nueva clave.
4. Notificar violación de integridad si se detectan firmas antiguas (512-bit) tras la migración.

## 4. Definición de Hecho (DoD)
- [ ] Nuevas claves generadas y persistidas en el Vault.
- [ ] Ejecución exitosa de `gov audit` confirmando firmas de 256 bytes (2048-bit).
- [ ] `baseline` estratégico completado con la nueva llave.
