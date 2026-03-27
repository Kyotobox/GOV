# TASK-DPI-S02-03: forensic_ledger.dart — ChainedLog en HISTORY.md

**Sprint**: S02-TELEMETRY
**Label**: [DATA]
**CP**: 4
**Gate**: GATE-AMBER
**Revisor**: [TECH] + [AUDIT]
**Modelo**: Gemini Flash

## Contexto
Implementar un sistema de log encadenado (Hash Chain) en `HISTORY.md`.
Cada entrada incluye el hash SHA-256 de la entrada anterior, haciendo imposible el borrado selectivo sin invalidar la cadena.
**Referencia Base2**: `Base2/ops-intelligence.ps1` — lógica de lectura de HISTORY.md para conteo de turnos.

## Scope
- `lib/src/telemetry/forensic_ledger.dart`

## Formato de Entrada HISTORY.md
```
| Fecha | SessionId | PrevHash | Tipo | Tarea | Detalle |
| 2026-03-25 15:51 | abc123 | 0000000 | EXEC | TASK-X | gov act |
| 2026-03-25 15:52 | abc123 | sha256(prev_row) | EXEC | TASK-X | gov baseline |
```

## Interfaz a Implementar
```dart
class ForensicLedger {
  // Agrega una entrada al log encadenado
  Future<void> appendEntry({
    required String sessionId,
    required String type,  // EXEC | SNAP | ALERT
    required String task,
    required String detail,
    required String basePath,
  });

  // Verifica la integridad de toda la cadena
  // Retorna lista de entradas corruptas (vacía = OK)
  Future<List<String>> verifyChain({String basePath});

  // Cuenta entradas de la sesión actual
  Future<int> countSessionEntries(String sessionId, {String basePath});
}
```

## DoD
- [ ] `appendEntry()` escribe en HISTORY.md con hash encadenado.
- [ ] `verifyChain()` detecta cualquier modificación manual.
- [ ] `countSessionEntries()` reemplaza la función de conteo de `ops-intelligence.ps1`.
- [ ] Tests: verificar que modificar manualmente HISTORY.md rompe la cadena.

## Baseline
`gov baseline "S02-03: ForensicLedger with ChainedLog implemented" GATE-AMBER`
