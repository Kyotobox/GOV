# TASK-DPI-S20: Ejecución de Pase a Producción (BASE2)

> **CONTEXTO AI**: Este sprint ejecuta las directivas trazadas en `TASK-DPI-BASE2.md`. Eres responsable de preparar el kernel para producción. **REGLA DE ORO:** Cualquier prueba unitaria fallida o archivo huérfano detectado aborta el pase a FASE 2.

## Tareas del Sprint

### [ ] TASK-DPI-S20-01: Deprecación Legacy (FASE 0)
- Eliminar físicamente los archivos `.ps1` y carpetas asociadas al antiguo sistema de validación `.ops` (excepto el script de entrada que lanza a Dart, si aplica).
- Actualizar cualquier documentación en `VISION.md` que referencie validación por PowerShell.
- **Validación**: Ejecutar `dart run bin/antigravity_dpi.dart detectOrphans` y confirmar que los `.ops` y `.ps1` eliminados no levanten alertas (o actualizar el manifiesto preventivamente si estaban registrados).

### [ ] TASK-DPI-S20-02: Auditoría y Sellado Atómico (FASE 1 y 2)
- **Paso 1**: Ejecutar `dart test test/`. Si hay fallos, el sprint se detiene para mitigación.
- **Paso 2**: Ejecutar el motor para limpiar cualquier huérfano temporal en `lib/` o `bin/`.
- **Paso 3**: Regenerar manifiesto `vault/kernel.hashes` ejecutando la rutina `generateHashes`.
- **Paso 4 (Aclaración BASE2)**: Preparar el comando CLI para la **Firma RSA de Producción**. *Nota para la IA: La llave privada de producción NO debe estar en el workspace. Instruye al Humano (PO) para que ejecute el comando final de firma.*

### [ ] TASK-DPI-S20-03: Cierre y Relevo Prod (FASE 3, 4 y 5)
- **Paso 1**: Preparar los comandos de Git para `commit` y `tag` (`git tag -a BASE2-PROD...`).
- **Paso 2**: Ejecutar el `gov handover` final para congelar el estado en `session.lock` y sellar el `HISTORY.md`.
- **Paso 3**: Notificar al Humano que el sistema está listo para el `gov takeover` en el entorno destino.

---

**CRITERIOS DE ACEPTACIÓN**:
1. No existen scripts `.ps1` obsoletos.
2. La suite de pruebas está al 100%.
3. El archivo `vault/kernel.hashes.sig` ha sido renovado y validado mediante llave pública.
4. El repositorio local está limpio (Working Tree Clean) y tageado como `BASE2-PROD`.