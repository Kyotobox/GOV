# TASK-DPI-S25-01: Hard Gate en `gov act`

## Contexto
El comando `gov act` actualmente se ejecuta sin verificar el nivel de saturación del núcleo.
Esto permite que el modelo opere en estado de fatiga crítica (>80% SHS), aumentando el riesgo
de alucinaciones, ignorar reglas de GEMINI.md, o corromper el backlog.json.

El objetivo es que `gov act` consulte el estado de saturación ANTES de registrar cualquier acción
y bloquee la ejecución si el umbral es superado.

## Archivos a Modificar

### Archivo principal
- `lib/src/kernel/gov.dart` — función: `runAct()`

### Archivo de soporte (ya existe, solo integrar)
- `lib/src/telemetry/telemetry_service.dart` — clase: `TelemetryService`, método: `computePulse()`

> **REGLA DPI-GATE-GOLD**: El motor `gov.dart` maneja la lógica de alto nivel.
> `TelemetryService` ya tiene `computePulse()` implementado. Solo debe ser llamado desde `runAct`.

## Implementación Paso a Paso

### Paso 1 — Localizar `runAct` en gov.dart
Busca la función `runAct(String basePath, List<String> args)`. Actualmente registra
la acción directamente sin ninguna verificación de saturación.

### Paso 2 — Insertar la verificación ANTES del registro de acción

```dart
Future<void> runAct(String basePath, List<String> args) async {
  // [S25-01] Pre-Gate: Verificar Saturación antes de permitir act
  final telemetry = TelemetryService();
  final pulse = await telemetry.computePulse(basePath: basePath);

  if (pulse.saturation >= 80) {
    print('\x1B[31m[YIELD] Saturación al ${pulse.saturation}%. Operación bloqueada por protocolo [DPI-GATE-GOLD].\x1B[0m');
    print('Ejecuta "gov handover" para sellar la sesión y liberar el núcleo.');
    exit(1);
  }

  if (pulse.saturation >= 60) {
    print('\x1B[33m[WARNING] Saturación al ${pulse.saturation}%. Considere un handover próximo.\x1B[0m');
  }

  // ... resto del código existente de runAct SIN CAMBIOS
```

### Paso 3 — Verificar importación de TelemetryService
En `gov.dart`, agregar import si no existe:
```dart
import 'package:antigravity_dpi/src/telemetry/telemetry_service.dart';
```

## Criterios de Aceptación
- [ ] `gov act "test"` con saturation < 60 → exit 0, sin warnings
- [ ] `gov act "test"` con saturation 60-79 → exit 0 + imprime `[WARNING] Saturación al X%.`
- [ ] `gov act "test"` con saturation >= 80 → exit 1 + imprime `[YIELD] Saturación al X%.`
- [ ] El mensaje de output incluye instrucción sobre `gov handover`

## Test Unitario Requerido

Crear o actualizar `test/telemetry_service_test.dart`:

```dart
// Test: Gov Act Hard Gate
test('gov act should be blocked when saturation >= 80', () async {
  // Crear sesión simulada con session_turns.txt = 999
  // Llamar computePulse → verificar saturation >= 80
  // Verificar que el gate retorna exit-equivalent
});
```

## Restricciones (NO HACER)
- NO modificar la lógica de registro de acciones (ForensicLedger) — solo agregar la pre-verificación
- NO cambiar los umbrales sin actualizar este archivo y `TASK-DPI-S25-02.md`
- El gate usa `exit(1)`, no `return` — debe interrumpir el proceso completo
