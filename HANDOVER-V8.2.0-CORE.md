# Vanguard Kernel v8.2.0 — Plan Verificado [ANALISIS ARQUITECTÓNICO]

## Análisis del Estado Actual del Motor

Tras una auditoria completa del código fuente, he mapeado la arquitectura real del sistema de telemetría para validar el plan y corregir suposiciones incorrectas.

---

### 🧠 Flujo CUS (Context Utilization Score) — Estado Actual

```
gov act / gov baseline
  └── TelemetryService.incrementTurns()
        └── vault/intel/session_turns.txt  [CONTADOR ATÓMICO]

gov pulse / gov audit
  └── CognitiveEngine.calculatePulse()
        └── ContextEngine.calculateCUS()
              ├── Fuente 1: .meta/session_pulse.json  (total_actions, chats)
              └── Fuente 2: Crawler de logs de conversación
                           ($USERPROFILE/.gemini/antigravity/brain/{UUID}/overview.txt)
                           [SOLO SI VANGUARD_CHAT_UUID está en el entorno]
              └── fórmula: (tool_calls * 1.2-2.0) + (chats * 0.5) → CUS%
```

> [!WARNING]
> **GAP CRÍTICO #1 — DOBLE FUENTE DE VERDAD PARA CUS**: El motor utiliza **dos sistemas de conteo paralelos** que NO están sincronizados:
> - `TelemetryService.incrementTurns()` escribe en `session_turns.txt` 
> - `ContextEngine.calculateCUS()` lee de `.meta/session_pulse.json` + el crawler de logs
> - `session_turns.txt` **NUNCA es leído por `ContextEngine.calculateCUS()`**
> - El CUS que se muestra en el Dual Dial proviene del crawler de logs o del `session_pulse.json`, **no del contador atómico**
> - Para Base2, donde `VANGUARD_CHAT_UUID` no está seteado, el crawler falla en silencio y el CUS queda en `0.0%` permanentemente.

---

### 🏥 Flujo BHI (Bunker Health Index) — Estado Actual

```
CognitiveEngine.calculatePulse()
  └── BunkerHealthEngine.calculateBHI()
        ├── IntegrityEngine.checkSwelling()  → densityScore (50% del peso)
        └── IntegrityEngine.checkZombies()  → zombieScore (5% por zombie)
        └── fórmula: (density/20 * 50) + (zombies * 5) → BHI%
```

> [!WARNING]
> **GAP #2 — BHI NO INCLUYE INTEGRIDAD CRIPTOGRÁFICA**: El BHI actual solo mide la **higiene de archivos** (densidad + zombies). No penaliza los fallos de `verifySelf()` (DNA mismatch). Un binario adulterado puede tener BHI=0% (limpio) pero estar comprometido.

---

### ⏱ Flujo Heartbeat del Agente (Vanguard Flutter) — Estado Actual

```
Timer(15s) → _runPulse()
  └── Process.run('gov pulse') 
        └── runPulse() en gov.dart
              └── CognitiveEngine.calculatePulse() + persistPulse()
                  └── intel_pulse.json [ACTUALIZADO]
  └── _refreshTelemetry() 
        └── Lee intel_pulse.json → variables _cus, _bhi
              └── Lee: data['cp_fatigue'] para _cus  ← COMPATIBILIDAD V7
              └── Lee: data['hygiene']['bhi'] para _bhi  ← CORRECTO (V8)
```

> [!NOTE]
> **Heartbeat funciona correctamente** end-to-end, EXCEPTO que el valor `cp_fatigue` que lee el agente proviene del CUS adulterado (sin crawler activo = 0%). El timer de 15 segundos es adecuado, no requiere cambio urgente.

---

### 🔑 Session UUID — Estado Actual

```
takeover → session.lock {chat_uuid: MANUAL-SESSION}  (no hay --uuid flag)
CognitiveEngine.calculatePulse()
  └── sessionUuid = Platform.environment['VANGUARD_CHAT_UUID'] ?? 'MANUAL-SESSION'
persistPulse() → intel_pulse.json {session_uuid: "MANUAL-SESSION"}
```

> [!WARNING]
> **GAP #3 — UUID ESTÁTICO**: El `takeover` nunca permite sobreescribir el UUID desde CLI. En Base2, donde el binario no tiene acceso a la variable de entorno `VANGUARD_CHAT_UUID`, el UUID siempre es `MANUAL-SESSION`, lo que rompe el crawler de logs del CUS.

---

## Proposed Changes — v8.2.0

### Prioridad ALTA (Necesaria para CUS Real)

#### [MODIFY] [gov.dart — ContextEngine.calculateCUS()](file:///c:/Users/Ruben/Documents/antigravity_dpi/lib/src/kernel/gov.dart)
- **Unificar la fuente de verdad del CUS**: El cálculo debe leer **primero** `vault/intel/session_turns.txt` (el contador atómico) como fuente principal.
- El crawler de logs es un complemento, solo si el UUID está disponible.
- Fórmula propuesta: `CUS% = min(100, (session_turns * 1.2) + (chat_count * 0.5))`
- Escala revisada: `100 turnos de herramienta ≈ 100% saturación` (actualmente 50 CP = 100%)

#### [MODIFY] [gov.dart — DualPulseData.toJson()](file:///c:/Users/Ruben/Documents/antigravity_dpi/lib/src/kernel/gov.dart)
- Asegurar que `cp_fatigue` (que lee el agente Flutter) = `context.cus` (que ya es el CUS unificado).
- El campo `bhi` debe leerlo el agente de `data['hygiene']['bhi']`, ya confirmado correcto.

---

### Prioridad ALTA (BHI Ponderado con Integridad)

#### [MODIFY] [gov.dart — BunkerHealthEngine.calculateBHI()](file:///c:/Users/Ruben/Documents/antigravity_dpi/lib/src/kernel/gov.dart)
- Añadir verificación de `verifyBinaryDNA()` al cálculo del BHI.
- **Nueva fórmula ponderada (70/30)**:
  - Salud de Integridad (0-70 pts): `isSelf ? 0 : 70`
  - Salud de Higiene (0-30 pts): `(density/20 * 15) + (zombies * 3)`
- Un DNA mismatch causa mínimo `BHI=70%` (estado FATIGA inmediato).

---

### Prioridad ALTA (UUID e Identity Relay)

#### [MODIFY] [gov.dart — runTakeover()](file:///c:/Users/Ruben/Documents/antigravity_dpi/lib/src/kernel/gov.dart)
- Añadir parsing de `--uuid <id>` en los argumentos de `takeover`.
- Al detectar el flag, escribir el UUID en `session.lock` Y en `vault/intel/intel_pulse.json`.
- Leer `SESSION_RELAY.json` si existe e inyectar sus valores en `session.lock`.

---

### Prioridad MEDIA (SSoT de Versión)

#### [NEW] [lib/src/version.dart](file:///c:/Users/Ruben/Documents/antigravity_dpi/lib/src/version.dart)
- `const String kKernelVersion = '8.2.0';`
- `const String kKernelBanner = 'VANGUARD KERNEL v8.2.0 [DPI-GATE-GOLD]';`

#### [MODIFY] [gov.dart](file:///c:/Users/Ruben/Documents/antigravity_dpi/lib/src/kernel/gov.dart)
- Reemplazar todas las instancias hardcodeadas de `v8.x.x`, `v8.0`, `v8.1`, `v8.1.5`  por `kKernelVersion`.
- Incluye los banners en: `main()`, `_printHelp()`, `_printTermHUD()`, `_runDashboard()`.

---

### Prioridad MEDIA (DNA-Seal Automatizado)

#### [MODIFY] [gov.dart — runSealDNA()](file:///c:/Users/Ruben/Documents/antigravity_dpi/lib/src/kernel/gov.dart)
- Después de generar el `gov_hash.sig`, ejecutar automáticamente `git rev-parse HEAD` y escribir el hash en `vault/intel/git_commit.txt`.
- El DNA_SEAL vinculará el hash del commit + el hash del binario para prevenir el "SELF-AUDIT FAIL" en nuevos entornos.

---

### Prioridad BAJA (Vanguard CLI Status & Reconcile)

#### [MODIFY] [main.dart — Vanguard Agent](file:///c:/Users/Ruben/Documents/antigravity_dpi/vanguard_agent/lib/main.dart)
- Detectar si se ejecuta con args (`vanguard.exe status`) antes de iniciar Flutter, e imprimir estado ASCII.

#### [MODIFY] [gov.dart — runSyncContext()](file:///c:/Users/Ruben/Documents/antigravity_dpi/lib/src/kernel/gov.dart)
- Implementar `--reconcile` para detectar desalineación `backlog.json` ↔ `task.md` y corregir automáticamente.

---

## Verification Plan

### Tests Críticos Post-Implementación
1. **CUS real**: `gov act` → `gov pulse` → verificar que `intel_pulse.json` tiene `cp_fatigue > 0`
2. **BHI con DNA**: Eliminar `gov_hash.sig` → `gov audit` → verificar que BHI ≥ 70%
3. **UUID sync**: `gov takeover --uuid TEST-123` → verificar campo `session_uuid` en `intel_pulse.json`
4. **SSoT versión**: `gov` (sin args) → debe mostrar `v8.2.0` en todos los banners

### Estimación de Trabajo
| Tarea | Complejidad | Impacto |
|:---|:---|:---|
| CUS unificado | Media | **ALTO** — Resuelve el 0% permanente en Base2 |
| BHI ponderado | Baja | ALTO — Detección real de compromiso |
| UUID relay | Baja | ALTO — Activa el crawler de logs |
| SSoT versión | Muy baja | MEDIO — Elimina confusión de versiones |
| DNA-Seal auto | Media | MEDIO — Previene falsos positivos |
| CLI status | Baja | BAJO — Comodidad operativa |
