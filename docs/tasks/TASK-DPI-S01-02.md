# TASK-DPI-S01-02: Crear Estructura de Directorios

**Sprint**: S01-GOV-BOOTSTRAP
**Label**: [SHELL]
**CP**: 1
**Gate**: GATE-BLUE
**Revisor**: [TECH] Gemini Flash
**Modelo**: Gemini Flash

## Contexto
Crear el árbol de directorios para todos los módulos planificados en el Plan Maestro.
Ejecutar después de TASK-DPI-S01-01.

## Scope:
- Creación de directorios vacíos en `lib/src/`
- Creación de archivos `.dart` vacíos con estructura mínima (solo export/library)

## Directorios a Crear
```
lib/src/core/
lib/src/security/
lib/src/telemetry/
lib/src/dash/
lib/src/tasks/
```

## Archivos a Crear (esqueleto mínimo)
Para cada archivo, el contenido inicial es solo el comentario de referencia:

```dart
// TASK-REF: [TASK-ID que lo implementará]
// Module: [nombre del módulo]
```

| Archivo | TASK-REF |
|---|---|
| `lib/src/core/cache_layer.dart` | TASK-DPI-S05-01 |
| `lib/src/core/parallel_runner.dart` | TASK-DPI-S05-01 |
| `lib/src/security/integrity_engine.dart` | TASK-DPI-S03-03 |
| `lib/src/security/vanguard_core.dart` | TASK-DPI-S03-01 |
| `lib/src/security/sign_engine.dart` | TASK-DPI-S03-02 |
| `lib/src/telemetry/telemetry_service.dart` | TASK-DPI-S02-01 |
| `lib/src/telemetry/forensic_ledger.dart` | TASK-DPI-S02-03 |
| `lib/src/dash/dashboard_engine.dart` | TASK-DPI-S04-03 |
| `lib/src/tasks/backlog_manager.dart` | TASK-DPI-S04-01 |
| `lib/src/tasks/compliance_guard.dart` | TASK-DPI-S04-02 |

## DoD
- [ ] Todos los directorios existen.
- [ ] Todos los archivos `.dart` de esqueleto existen con comentario de referencia.
- [ ] `dart analyze` retorna 0 issues.
- [ ] Self-Audit Obligatorio (`gov audit`) verificado antes del baseline.

## Baseline
`gov baseline "S01-02: Directory structure scaffolded" GATE-BLUE`
