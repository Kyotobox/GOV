# TASK-DPI-S02-01: telemetry_service.dart — Motor SHS Completo

**Sprint**: S02-TELEMETRY
**Label**: [DATA]
**CP**: 5
**Gate**: GATE-AMBER
**Revisor**: [TECH] Gemini Flash + [AUDIT]
**Modelo**: Gemini Flash

## Contexto
Implementar en Dart el equivalente a `ops-intelligence.ps1::Invoke-CognitiveTracker`.
**Referencia Base2**: `Base2/ops-intelligence.ps1` líneas 51-205.
**Referencia Data**: `Base2/vault/intel/intel_pulse.json` (estructura de salida esperada).

El SHS se calcula como:
```
FinalCP = (tools * 1.2) + (chats * 0.5) + swelling + time_tax + velocity_tax + zombie_penalty + passive_fatigue
SHS% = min(100, round(FinalCP / 0.5))
```

## Scope
- `lib/src/telemetry/telemetry_service.dart` (ÚNICO archivo a crear)

## Interfaz Pública a Implementar
```dart
class TelemetryService {
  // Calcula el SHS actual leyendo session_turns.txt, chat_count.txt, session.lock, HISTORY.md
  Future<PulseSnapshot> computePulse({String basePath});

  // Persiste intel_pulse.json con hash SHA-256 embebido (Signed Pulse)
  Future<void> persistPulse(PulseSnapshot pulse, {String basePath});

  // Incrementa session_turns.txt de forma atómica con checksum
  Future<int> incrementTurns({String basePath});
}

class PulseSnapshot {
  final double cp;
  final int saturation;
  final Map<String, dynamic> cpDetail;
  final String timestamp;
  final String contentHash; // SHA-256 del JSON sin esta clave
}
```

## Correcciones Respecto a Base2
1. **velocity_tax**: Usar `session.lock` timestamp como fallback si `HISTORY.md` está vacío.
2. **swelling**: Sin cap artificial. Emitir `SWELLING_ALERT` si supera 20 CP.
3. **Signed Pulse**: Incluir `contentHash` (SHA-256) en `intel_pulse.json`.

## DoD
- [ ] Clase `TelemetryService` implementada con los 3 métodos públicos.
- [ ] `computePulse()` produce el mismo resultado que `Invoke-CognitiveTracker` para los mismos inputs.
- [ ] `persistPulse()` escribe `intel_pulse.json` con `contentHash` SHA-256.
- [ ] `dart test` pasa: tests unitarios con valores conocidos de SHS.

## Baseline
`gov baseline "S02-01: TelemetryService implemented with Signed Pulse" GATE-AMBER`
