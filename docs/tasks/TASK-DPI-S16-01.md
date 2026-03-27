# TASK-DPI-S16-01: Auto-Commit Semántico y Estandarizado

**Sprint**: S16-FACTORY-OPS
**Label**: [OPS]
**CP**: 2
**Gate**: GATE-BLUE
**Revisor**: [TECH]
**Modelo**: Gemini Flash

## Contexto
Automatizar la generación de mensajes de commit para `gov baseline` utilizando la metadata de la tarea activa (`task.md`), asegurando consistencia y trazabilidad.

## Scope
- `bin/antigravity_dpi.dart`
- `lib/src/tasks/backlog_manager.dart`
- `TASK-DPI-S16-01.md`

## DoD
- [ ] `gov baseline` genera automáticamente un mensaje de commit en formato `feat(SPRINT-ID): TASK-ID - Descripción de la tarea`.
- [ ] El mensaje de commit se extrae de `task.md` y `backlog.json`.
- [ ] El mensaje de commit es inyectado en el comando `git commit -m "..."`.