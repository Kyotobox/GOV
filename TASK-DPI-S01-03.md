# TASK-DPI-S01-03: Definir VISION.md del Proyecto

**Sprint**: S01-GOV-BOOTSTRAP
**Label**: [GOV]
**CP**: 2
**Gate**: GATE-RED
**Revisor**: [GOV] PO
**Modelo**: Gemini Flash

## Contexto
Formalizar la visión del proyecto `antigravity_dpi` como Control Plane independiente de Base2.

## Scope
- `VISION.md` (ÚNICO archivo modificable)

## Contenido a Escribir
```markdown
# VISION.md — antigravity_dpi (gov.exe)

## IDENTIDAD
Control Plane (Plano de Gobernanza) para el ecosistema Base2.
Compilado a `gov.exe` — binario 100% Dart, sin dependencias Flutter ni PowerShell.

## RESPONSABILIDADES
1. Verificar integridad del Kernel (SHA-256 + RSA).
2. Calcular y firmar métricas de telemetría (SHS/Pulse).
3. Orquestar cumplimiento de tareas (backlog, task.md, DASHBOARD.md).
4. Gestionar el ciclo Handover/Takeover de sesiones.

## CERCAS ELÉCTRICAS
- NO lógica de UI. Solo CLI.
- NO llamadas externas a PowerShell para operaciones criptográficas.
- NO modificar archivos fuera del scope de la tarea activa.
- NO baseline sin firma RSA para cambios GATE-RED o superior.
```

## DoD
- [ ] `VISION.md` creado con el contenido anterior.
- [ ] El archivo no supera 50 líneas.

## Baseline
`gov baseline "S01-03: VISION.md formalized" GATE-RED`
