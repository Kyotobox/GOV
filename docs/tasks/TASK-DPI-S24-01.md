# TASK-DPI-S24-01: Detección de Cambios en Núcleo (BLACK-GATE Trigger)

## Metadatos
- **Sprint**: S24-BLACKGATE
- **Label**: GOV
- **Gate**: STRATEGIC-GOLD
- **Dependencias**: S23 completado
- **Archivos en Scope**: `bin/antigravity_dpi.dart`

## Objetivo
El método `issueChallenge` debe detectar si los archivos del núcleo (`GEMINI.md`, `VISION.md`, `lib/src/security/`) han cambiado respecto al último baseline. Si hay cambios, elevar automáticamente el nivel del desafío a `BLACK-GATE` e incluir el hash de los cambios en el ID del desafío.

## Archivos "Core" que activan BLACK-GATE
```dart
static const List<String> kCoreFiles = [
  'GEMINI.md',
  'VISION.md',
  'COMMANDS.md',
  'lib/src/security/sign_engine.dart',
  'lib/src/security/integrity_engine.dart',
  'lib/src/security/vanguard_core.dart',
];
```

## Pasos de Ejecución

### Paso 1: Añadir función de detección de cambios en núcleo
En `bin/antigravity_dpi.dart`, agregar función top-level:

```dart
/// Detecta si algún archivo del núcleo ha cambiado desde el último commit.
/// Retorna el hash de los cambios si hay, o null si no hay cambios en núcleo.
Future<String?> _detectCoreChanges(String basePath) async {
  const kCoreFiles = [
    'GEMINI.md',
    'VISION.md',
    'COMMANDS.md',
    'lib/src/security/sign_engine.dart',
    'lib/src/security/integrity_engine.dart',
    'lib/src/security/vanguard_core.dart',
  ];
  
  try {
    final result = await Process.run(
      'git',
      ['diff', '--name-only', 'HEAD'],
      workingDirectory: basePath,
    );
    
    if (result.exitCode != 0) return null;
    
    final changedFiles = (result.stdout as String)
        .split('\n')
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();
    
    final coreChanges = changedFiles
        .where((f) => kCoreFiles.any((core) => f.contains(core)))
        .toList();
    
    if (coreChanges.isEmpty) return null;
    
    // Calcular hash de la lista de archivos cambiados
    final changesStr = coreChanges.join('|');
    final hash = sha256.convert(utf8.encode(changesStr)).toString().substring(0, 12);
    return 'CORE-CHANGE-$hash';
  } catch (_) {
    return null;
  }
}
```

### Paso 2: Modificar `issueChallenge` para usar la detección
```dart
Future<String> issueChallenge(String basePath, {String level = 'KERNEL'}) async {
  // Detectar si hay cambios en el núcleo
  final coreChangeHash = await _detectCoreChanges(basePath);
  String effectiveLevel = level;
  String challengeId = 'AUTH-DPI-GOLD';
  
  if (coreChangeHash != null) {
    effectiveLevel = 'BLACK-GATE';
    challengeId = coreChangeHash; // El ID contiene el hash de los cambios
    print('[!] ALERTA BLACK-GATE: Cambios en archivos del núcleo detectados.');
    print('[!] Challenge ID: $challengeId');
  }
  
  final intelDir = p.join(basePath, 'vault', 'intel');
  if (!Directory(intelDir).existsSync()) Directory(intelDir).createSync(recursive: true);
  
  await File(p.join(intelDir, 'challenge.json')).writeAsString(jsonEncode({
    'challenge': challengeId,
    'level': effectiveLevel,
    'timestamp': DateTime.now().toIso8601String(),
  }));
  
  print('[VANGUARD] Desafío generado: $challengeId (Nivel: $effectiveLevel)');
  return challengeId;
}
```

### Paso 3: Asegurar que `crypto` está importado
```dart
import 'package:crypto/crypto.dart';
```

## Criterio de Éxito
- Modificar `GEMINI.md` sin commitear → `baseline` emite desafío de nivel `BLACK-GATE` con ID `CORE-CHANGE-XXXXXXXX`.
- Sin modificaciones en núcleo → `baseline` emite desafío de nivel `KERNEL`.
- `dart analyze` → 0 errores.

## Criterio de Fallo (DETENER si ocurre)
- El nivel BLACK-GATE no se activa al modificar `GEMINI.md`.
- `dart analyze` reporta errores.
