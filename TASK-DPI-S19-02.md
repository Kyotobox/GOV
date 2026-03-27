# TASK-DPI-S19-02: Apretón de Manos RSA Táctico (Handover)

**Estado**: PENDING
**Prioridad**: HIGH (GATE-RED)
**CP**: 10.0

## 1. Descripción
Endurecer el proceso de `handover` (cierre de sesión) para que requiera una firma RSA explícita del desafío táctico emitido por `Vanguard`. Actualmente, el sistema acepta la presencia de `signature.json` sin validar criptográficamente su contenido.

## 2. Alcance (Scope)
- `lib/src/security/vanguard_core.dart`
- `bin/antigravity_dpi.dart` (runHandover)
- `test/security_hardening_test.dart`

## 3. Requerimientos Operativos
1. Modificar `runHandover` para pasar la `publicKeyXml` a `vanguard.waitForSignature`.
2. El sistema debe abortar el cierre de sesión si la firma no coincide con el desafío táctico.
3. Implementar protección contra ataques de repetición (Replay Protection) mediante el borrado atómico del archivo de firma.

## 4. Definición de Hecho (DoD)
- [ ] `handover` falla si se intenta cerrar con un archivo de firma corrupto o firmado con la clave incorrecta.
- [ ] Logs forenses registran la verificación exitosa de la firma táctica.
- [ ] Suite de tests validando el handshake táctico en verde.
