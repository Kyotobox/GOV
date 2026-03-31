# TASK-DPI-S25-06: Fleet Pulse Auto-Update

## Contexto
`fleet_pulse.json` es el dashboard central de telemetría de la flota. Actualmente solo se actualiza
cuando se ejecuta `gov fleet-pulse` manualmente. Vanguard ya tiene un heartbeat de 15 segundos
que ejecuta `gov pulse`, pero este solo actualiza `intel_pulse.json` del proyecto activo.

El objetivo es que el heartbeat de Vanguard (cada 15s) también actualice `fleet_pulse.json`,
dando visibilidad en tiempo real del estado de todos los proyectos registrados.

## Estrategia

La forma más limpia es hacer que `runPulse()` en `gov.dart` también dispare la agregación
de la flota al final. Esto mantiene la responsabilidad en el Motor, no en el UI.

## Archivos a Modificar
- `lib/src/kernel/gov.dart` — función: `runPulse()`

## Implementación Paso a Paso

### Paso 1 — Al final de `runPulse()`, llamar la agregación de flota

Localizar `runPulse()` (línea ~1166 en gov.dart). Al final de la función, después de
actualizar `intel_pulse.json`, añadir:

```dart
Future<void> runPulse(String basePath, List<String> args) async {
  try {
    // ... código existente de pulse sin cambios ...

    // [S25-06] Auto-actualizar fleet_pulse.json después de cada heartbeat
    await runFleetPulse(basePath, ['--silent']); // --silent para no imprimir en stdout
  } catch (e) {
    print('[ERROR] Orquestación de Pulso fallida: $e');
  }
}
```

### Paso 2 — Agregar flag `--silent` en `runFleetPulse()`

En `runFleetPulse()` (línea ~1768):

```dart
Future<void> runFleetPulse(String basePath, List<String> args) async {
  final isSilent = args.contains('--silent'); // [S25-06] NUEVO

  if (!isSilent) print('=== [GOV] FLEET TELEMETRY AGGREGATOR [DPI-GATE-GOLD] ===');

  // ... código existente, reemplazando todos los print() por:
  if (!isSilent) print('  [OK] $name (CUS: $cus% | BPI: $bpi%)');
  // etc.
```

> Solo los prints informativos de progreso deben ser silenciados. Los errores (`[ERROR]`) deben
> imprimirse siempre para depuración.

### Paso 3 — Proteger contra loops de error

Si `fleet_registry.json` no existe o está mal formado durante el pulso silencioso, NO debe
crashear el proceso de pulse. Agregar manejo de errores:

```dart
// En runPulse(), envolver la llamada a fleet pulse:
try {
  final registryFile = File(p.join(basePath, 'vault', 'intel', 'fleet_registry.json'));
  if (await registryFile.exists()) {
    await runFleetPulse(basePath, ['--silent']);
  }
} catch (fleetError) {
  // Error silencioso en fleet pulse — no debe interrumpir el pulse individual
}
```

## Comportamiento Esperado Post-Implementación

```
[Heartbeat cada 15s en Vanguard]
  → gov pulse
     → Actualiza vault/intel/intel_pulse.json del proyecto activo
     → Actualiza vault/intel/fleet_pulse.json con estado de TODOS los proyectos
  → Vanguard detecta cambio en intel_pulse.json (DirectoryWatcher)
  → Refresca telemetría en el HUD
```

## Criterios de Aceptación
- [ ] `gov pulse` actualiza tanto `intel_pulse.json` como `fleet_pulse.json`
- [ ] `gov pulse` con búnker sin `fleet_registry.json` no crashea
- [ ] `fleet_pulse.json` tiene timestamp actualizado (máx 16s de diferencia con la hora real)
- [ ] `gov fleet-pulse` sin flag sigue funcionando con output completo (no silenciado)
- [ ] No hay regresión en el tiempo de ejecución de `gov pulse` (< 2s adicionales)

## Restricciones (NO HACER)
- NO ejecutar `gov fleet-pulse` en modo --silent si el fleet_registry.json no existe
- NO imprimir output del fleet pulse en el stdout normal de `gov pulse` (rompe parsing del HUD)
