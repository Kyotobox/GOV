# TASK-DPI-S15-01: Generador de Contexto (gov context)

**Sprint**: S15-SYMBIOSIS
**Label**: [AI-CORE]
**CP**: 3
**Gate**: GATE-RED
**Revisor**: [ARCH]
**Modelo**: Gemini Flash

## Contexto
Crear un comando `gov context` que genere un archivo curado (`vault/ai_context.txt`) con el código fuente de los archivos dentro del `Scope` de la tarea activa, el `DASHBOARD.md` y el `GEMINI.md`. Esto focaliza a la IA, reduce el consumo de tokens y previene alucinaciones.

## Scope
- `bin/antigravity_dpi.dart`
- `lib/src/core/context_engine.dart` (Nuevo)
- `lib/src/tasks/compliance_guard.dart`
- `vault/ai_context.txt`
- `TASK-DPI-S15-01.md`

## DoD
- [ ] Nuevo comando `gov context` implementado.
- [ ] `gov context` genera `vault/ai_context.txt` con el contenido de los archivos en el `Scope` de la tarea activa.
- [ ] `vault/ai_context.txt` incluye el contenido de `DASHBOARD.md` y `GEMINI.md`.
- [ ] `gov context` registra una entrada `SNAP | CONTEXT` en `HISTORY.md`.