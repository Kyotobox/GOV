# TASK-DPI-S22-02: Relay Atómico con Hash de Git en Handover/Takeover

## Metadatos
- **Sprint**: S22-LEDGER
- **Label**: GOV
- **Gate**: OPERATIONAL-RED
- **Dependencias**: TASK-DPI-S22-01 completada
- **Archivos en Scope**: `bin/antigravity_dpi.dart` (funciones `_runHandover`, `_runTakeover`)

## Objetivo
El relay de sesión (`SESSION_RELAY_TECH.md` o equivalente) debe incluir el hash de Git (`HEAD`) en el momento del handover. El `takeover` verifica que el hash del relay coincide con el hash actual del repositorio antes de iniciar la sesión.

## Pre-flight Check
```powershell
git rev-parse HEAD
```
Debe devolver un hash SHA-1 de 40 caracteres.

## Pasos de Ejecución

### Paso 1: Función utilitaria para obtener el hash de Git
Agregar en `bin/antigravity_dpi.dart` como función top-level:

```dart
/// Obtiene el hash de HEAD del repositorio git.
/// Retorna null si no es un repositorio git o si git no está disponible.
Future<String?> _getGitHash(String basePath) async {
  try {
    final result = await Process.run(
      'git',
      ['rev-parse', 'HEAD'],
      workingDirectory: basePath,
    );
    if (result.exitCode == 0) {
      return (result.stdout as String).trim();
    }
    return null;
  } catch (_) {
    return null;
  }
}
```

### Paso 2: Incluir el hash en `_runHandover`
En el método `_runHandover`, antes de escribir el relay:

```dart
Future<void> _runHandover(String basePath) async {
  print('=== [GOV] SESSION HANDOVER ===');
  await _runAudit(basePath);
  
  final gitHash = await _getGitHash(basePath);
  final timestamp = DateTime.now().toIso8601String();
  
  // Escribir el relay con el hash de Git
  final relayFile = File(p.join(basePath, 'SESSION_RELAY_TECH.md'));
  await relayFile.writeAsString('''
# SESSION RELAY - HANDOVER SEALED
- **Timestamp**: $timestamp
- **GitHash**: ${gitHash ?? 'N/A (no git)'}
- **Status**: HANDOVER_SEALED
''');
  
  // Guardar el hash en el session.lock para que takeover lo valide
  final lockFile = File(p.join(basePath, 'session.lock'));
  await lockFile.writeAsString(jsonEncode({
    'status': 'HANDOVER_SEALED',
    'timestamp': timestamp,
    'gitHash': gitHash,
  }));
  
  print('[OK] Relay sellado. GitHash: ${gitHash?.substring(0, 8) ?? 'N/A'}...');
}
```

### Paso 3: Validar el hash en `_runTakeover`
En el método `_runTakeover`, al inicio:

```dart
Future<void> _runTakeover(String basePath) async {
  print('=== [GOV] SESSION TAKEOVER ===');
  
  // Leer el relay de la sesión anterior
  final lockFile = File(p.join(basePath, 'session.lock'));
  if (lockFile.existsSync()) {
    final lockData = jsonDecode(await lockFile.readAsString());
    final relayHash = lockData['gitHash'] as String?;
    
    if (relayHash != null) {
      final currentHash = await _getGitHash(basePath);
      if (currentHash != null && relayHash != currentHash) {
        print('[WARNING] GitHash ha cambiado desde el último Handover.');
        print('  Relay:   ${relayHash.substring(0, 8)}...');
        print('  Actual:  ${currentHash.substring(0, 8)}...');
        print('[INFO] Esto es normal si se realizaron commits. Continuando...');
      } else {
        print('[OK] Continuidad verificada. GitHash: ${relayHash.substring(0, 8)}...');
      }
    }
  }
  
  await _runAudit(basePath);
  print('[OK] Sesión iniciada y sincronizada.');
}
```

> [!NOTE]
> El takeover NO bloquea si el hash cambió (puede haber commits legítimos). Solo lo reporta para que el PO sepa qué ocurrió entre sesiones.

## Criterio de Éxito
- `gov handover` genera `SESSION_RELAY_TECH.md` con el campo `GitHash`.
- `gov handover` actualiza `session.lock` con el hash.
- `gov takeover` lee el relay y reporta la concordancia o divergencia del hash.
- `dart analyze` → 0 errores.

## Criterio de Fallo (DETENER si ocurre)
- El handover no incluye el hash de Git en el relay.
- El takeover no lee el relay previo.
