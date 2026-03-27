# TASK-DPI-S05-03: gov handover y gov takeover — CLI Nativo

**Sprint**: S05-CLI
**Label**: [SHELL]
**CP**: 4
**Gate**: GATE-RED
**Revisor**: [TECH] + [GOV] PO
**Modelo**: Gemini Flash

## Contexto
Implementar los comandos `gov handover` y `gov takeover` directamente en Dart,
replicando y mejorando la lógica de `ops-gov.ps1` líneas 238-397.
**Referencia Base2**: `Base2/ops-gov.ps1` — sección `handover` (L238) y `takeover` (L398).
**Datos Base2**: El relay técnico se escribe en `vault/brain/SESSION_RELAY_TECH.md`.

## Scope:
- `bin/antigravity_dpi.dart` — comandos `handover` y `takeover`
- `lib/src/telemetry/telemetry_service.dart` — método `resetCounters()`

## Flujo Handover (gov handover)
```
1. Calcular SHS final → TelemetryService.computePulse()
2. Leer sprint activo → BacklogManager.getActiveSprint()
3. Generar SESSION_RELAY_TECH.md:
   - SHS al cierre
   - Sprint activo + tareas pendientes
   - Git hash del último commit
   - Señal de continuidad (siguiente sprint)
4. Emitir challenge RSA GATE-AMBER → VanguardCore.issueChallenge()
5. Esperar firma PO → VanguardCore.watchChallenges() (timeout: 120s)
6. Si firmado: SignEngine.verify() → AtomicBaseline (via git)
7. Resetear session_turns.txt → TelemetryService.resetCounters()
8. Sellar session.lock con status: HANDOVER_SEALED
9. Regenerar DASHBOARD.md → DashboardEngine.generate()
```

## Flujo Takeover (gov takeover [session-id])
```
1. Verificar session.lock no esté activo (o sea HANDOVER_SEALED)
2. Leer SESSION_RELAY_TECH.md
3. Imprimir contexto condensado al PO
4. Ejecutar IntegrityEngine.verifyAll() → 0 failures requerido
5. Ejecutar TelemetryService.computePulse() → mostrar SHS inicial
6. Crear nuevo session.lock con timestamp actual
7. Mostrar primera tarea pendiente del sprint activo
```

## Formato SESSION_RELAY_TECH.md
```markdown
# SESSION RELAY TÉCNICO
Generado: 2026-03-25 16:00 | Tipo: HANDOVER

## Estado SHS al Cierre
- SHS: 56% | CP: 28.2
- Tools: 2 | Chats: 2 | Swelling: 15

## Sprint Activo al Cierre
- Sprint: S02-TELEMETRY
- Progreso: 2/5 tareas completadas
- Tareas pendientes:
  - TASK-DPI-S02-03: ForensicLedger [PENDING]
  - TASK-DPI-S02-04: Watch Mode [PENDING]

## Contexto Git
- Rama: gov-gold-amend-037
- Ultimo Commit: 6dc4a4b baseline: S02-01 Signed

## SEÑAL DE CONTINUIDAD
- SPRINT_SIGUIENTE: S02-TELEMETRY
- ACCION_REQUERIDA: gov takeover
```

## DoD
- [ ] `gov handover` genera SESSION_RELAY_TECH.md completo.
- [ ] `gov handover` fuerza baseline RSA antes de sellar.
- [ ] `gov takeover` lee el relay y muestra resumen al PO en <2s.
- [ ] `gov takeover` bloquea si NO hay HANDOVER_SEALED en session.lock.
- [ ] Tests: simular handover/takeover en directorio temporal.
- [ ] Self-Audit Obligatorio (`gov audit`) verificado antes del baseline.

## Baseline (requiere firma RSA del PO)
`gov baseline "S05-03: Native handover/takeover implemented" GATE-RED`
