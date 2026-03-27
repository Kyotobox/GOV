# TASK-DPI-S23-03: Sincronización de Niveles de Seguridad (CLI ↔ Vanguard UI)

## Metadatos
- **Sprint**: S23-VANGUARD
- **Label**: UI
- **Gate**: STRATEGIC-GOLD
- **Dependencias**: TASK-DPI-S23-02 completada
- **Archivos en Scope**: `vanguard_agent/lib/main.dart`, `bin/antigravity_dpi.dart`

## Objetivo
El CLI emite desafíos con niveles de seguridad. El Agente Vanguard debe reconocer y visualizar correctamente cada nivel. Verificar y corregir la tabla de correspondencia entre CLI y UI.

## Tabla de Correspondencia (Source of Truth)

| CLI emite (`level`) | UI muestra | Color de fondo | Patrón de alarma |
|---|---|---|---|
| `BLACK-GATE` | `☠ VANGUARD: BLACK GATE (EMERGENCY)` | Negro con pulso rojo | 5 beeps rápidos |
| `KERNEL-CORE` | `⚖ VANGUARD: GOLD INMUTABLE` | Ámbar oscuro | 3 beeps medios |
| `KERNEL` | `⚠️ VANGUARD: KERNEL RED` | Rojo oscuro | 2 beeps lentos |
| `TACTICAL` | `📈 VANGUARD: TACTICAL ORANGE` | Naranja oscuro | 1 click |
| (vacío/null) | `🔒 VANGUARD: OPERATIONAL` | Cyan oscuro | Silencio |

## Pasos de Ejecución

### Paso 1: Verificar que `issueChallenge` en el CLI emite el campo `level`
En `bin/antigravity_dpi.dart`, en el método `issueChallenge` de `VanguardCore`:

```dart
Future<String> issueChallenge(String basePath, {String level = 'KERNEL'}) async {
  const challenge = 'AUTH-DPI-GOLD';
  final intelDir = p.join(basePath, 'vault', 'intel');
  if (!Directory(intelDir).existsSync()) Directory(intelDir).createSync(recursive: true);
  
  await File(p.join(intelDir, 'challenge.json')).writeAsString(jsonEncode({
    'challenge': challenge,
    'level': level,           // ← CRÍTICO: Este campo debe existir siempre
    'timestamp': DateTime.now().toIso8601String(),
  }));
  print('[VANGUARD] Desafío generado: $challenge (Nivel: $level)');
  return challenge;
}
```

### Paso 2: Llamar a `issueChallenge` con el nivel correcto en `_runBaseline`
```dart
// Para baseline estándar:
final challengeId = await vanguard.issueChallenge(basePath, level: 'KERNEL');
```

### Paso 3: Verificar el `_loadChallenge` en el Agente Vanguard
En `vanguard_agent/lib/main.dart`, verificar que `_loadChallenge` lee el campo `level`:
```dart
_level = data['level'] ?? 'TACTICAL'; // Default a TACTICAL si no hay nivel
```
Este código ya debe existir. Confirmar que el default es correcto.

### Paso 4: Verificar el método `_playLevelAlarm`
Comparar el método contra la tabla de correspondencia y corregir si hay diferencias:
```dart
void _playLevelAlarm(String? level) {
  if (level == 'BLACK-GATE') {
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () => SystemSound.play(SystemSoundType.alert));
    }
  } else if (level == 'KERNEL-CORE') {
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 400), () => SystemSound.play(SystemSoundType.alert));
    }
  } else if (level == 'KERNEL') {
    for (int i = 0; i < 2; i++) {
      Future.delayed(Duration(milliseconds: i * 600), () => SystemSound.play(SystemSoundType.alert));
    }
  } else {
    SystemSound.play(SystemSoundType.click);
  }
}
```

### Paso 5: Test manual de round-trip
1. Ejecutar `dart bin/antigravity_dpi.dart baseline "Test S23"` → genera `challenge.json` con `level: KERNEL`.
2. Abrir el Agente Vanguard (si está compilado) → debe mostrar fondo rojo y 2 beeps.
3. Firmar manualmente → el baseline debe completarse.

## Criterio de Éxito
- `challenge.json` incluye el campo `level` con valor adecuado.
- `flutter analyze vanguard_agent/` → 0 errores.
- La tabla de correspondencia es correcta en el código del agente.

## Criterio de Fallo (DETENER si ocurre)
- `challenge.json` no incluye el campo `level`.
- El agente muestra un nivel incorrecto para el desafío emitido.
