# TASK-DPI-S25-02: Conectar `incrementTurns` al flujo de `gov act` y `gov baseline`

## Contexto
`TelemetryService.incrementTurns()` ya está implementado en `telemetry_service.dart` (línea 121).
Sin embargo, NUNCA se llama desde ningún comando del motor. Esto hace que:
- `session_turns.txt` se quede siempre en 0
- CUS (Context Utilization Score) reporte permanentemente 0%
- El sistema de saturación sea ciego a la actividad de la sesión

Esta tarea hace que cada `gov act` y `gov baseline` incrementen el contador de turnos,
dándole vida al CUS y habilitando el Hard Gate de la TASK-DPI-S25-01.

## Dependencia
⚠️ Esta tarea debe ejecutarse ANTES que TASK-DPI-S25-01, ya que sin turnos reales el
Hard Gate de saturación nunca se activará.

## Archivos a Modificar
- `lib/src/kernel/gov.dart` — funciones: `runAct()`, `_runBaseline()`

## Implementación Paso a Paso

### Paso 1 — En `runAct()`, llamar `incrementTurns` al inicio

```dart
Future<void> runAct(String basePath, List<String> args) async {
  // [S25-02] Incrementar contador de turnos ANTES del pre-gate
  final telemetry = TelemetryService();
  await telemetry.incrementTurns(basePath: basePath);

  // [S25-01] Pre-Gate de Saturación (de TASK-S25-01)
  final pulse = await telemetry.computePulse(basePath: basePath);
  // ... resto del gate y lógica existente
```

> **IMPORTANTE**: Llamar `incrementTurns` ANTES de `computePulse` para que el pulso
> ya refleje el turno actual en el gate.

### Paso 2 — En `_runBaseline()`, también incrementar

```dart
Future<void> _runBaseline(String basePath, String detail) async {
  // [S25-02] Un baseline también cuenta como interacción significativa
  final telemetry = TelemetryService();
  await telemetry.incrementTurns(basePath: basePath);

  // ... resto del código existente SIN CAMBIOS
```

### Paso 3 — Confirmar que `runHandover` llama `resetCounters()`
En `runHandover()`, verificar que existe una llamada a `telemetry.resetCounters(basePath: basePath)`.
Si no existe, agregarla ANTES del cierre de la session.lock:

```dart
final telemetry = TelemetryService();
await telemetry.resetCounters(basePath: basePath);
```

### Paso 4 — Verificar archivos en el búnker
Confirmar que existen (o crearlos vacíos si no existen):
- `vault/intel/session_turns.txt` (contenido: `0`)
- `vault/intel/chat_count.txt` (contenido: `0`)

## Criterios de Aceptación
- [ ] Ejecutar `gov act "test"` 3 veces → `vault/intel/session_turns.txt` contiene `3`
- [ ] `gov baseline "test"` → `session_turns.txt` incrementa en 1 adicional
- [ ] `gov handover` → `session_turns.txt` resetea a `0`
- [ ] `gov pulse` tras los pasos anteriores → CUS refleja valor > 0%

## Test Unitario Requerido

```dart
test('incrementTurns should update session_turns.txt atomically', () async {
  // Crear basePath temporal con vault/intel/session_turns.txt vacío
  final service = TelemetryService();
  await service.incrementTurns(basePath: tmpPath);
  await service.incrementTurns(basePath: tmpPath);
  await service.incrementTurns(basePath: tmpPath);
  final content = File('$tmpPath/vault/intel/session_turns.txt').readAsStringSync();
  expect(int.parse(content.trim()), equals(3));
});

test('resetCounters should set session_turns.txt to 0', () async {
  final service = TelemetryService();
  await service.incrementTurns(basePath: tmpPath); // Simular 1 turno
  await service.resetCounters(basePath: tmpPath);
  final content = File('$tmpPath/vault/intel/session_turns.txt').readAsStringSync();
  expect(content.trim(), equals('0'));
});
```

## Restricciones (NO HACER)
- NO modificar la formula de CUS en `TelemetryService.computePulse()` — solo activar las entradas
- NO reiniciar contadores manualmente salvo desde `resetCounters()`
