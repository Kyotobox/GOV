# TASK-DPI-S10-02: Comando de Exportación para Auditoría (gov pack)

**Sprint**: S10-FLEET
**Label**: [CLI]
**CP**: 3
**Gate**: GATE-RED
**Revisor**: [TECH]
**Modelo**: Gemini Flash

## Contexto
En Base2 existía un proceso de PowerShell para generar un `.zip` del código y enviarlo a auditoría. Necesitamos incorporar esta capacidad de forma nativa en `gov.exe` mediante un comando `gov pack`. Este comando debe empaquetar el proyecto actual de forma limpia, omitiendo directorios pesados que no son relevantes para un auditor de código o una IA.

## Scope
- `bin/antigravity_dpi.dart`
- `lib/src/core/pack_engine.dart`
- `COMMANDS.md`
- `pubspec.yaml`
- `TASK-DPI-S10-02.md`

## DoD
- [ ] Agregar el paquete `archive` a `pubspec.yaml` para el manejo de archivos ZIP nativo en Dart.
- [ ] Crear la clase `PackEngine` que lea el `basePath` y genere un archivo `audit_export.zip` en la raíz.
- [ ] El empaquetador DEBE excluir carpetas/archivos basura o sensibles: `.git/`, `.dart_tool/`, `build/`, y opcionalmente `session.lock`.
- [ ] Registrar el comando `pack` en `bin/antigravity_dpi.dart`.
- [ ] Como medida de seguridad, `gov pack` debe ejecutar `runAudit(basePath)` primero. Solo se empaquetan Kernels que pasen la auditoría de integridad.
- [ ] Documentar el nuevo comando en `COMMANDS.md`.