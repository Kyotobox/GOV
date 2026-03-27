# TASK-DPI-S21-03: Bloqueo Git-Zero Pre-Baseline

## Metadatos
- **Sprint**: S21-RESTORE
- **Label**: GOV
- **Gate**: OPERATIONAL-RED
- **Dependencias**: TASK-DPI-S21-01 completada
- **Archivos en Scope**: `bin/antigravity_dpi.dart`

## Objetivo
Garantizar que el sellado criptográfico (`baseline`) solo ocurra sobre un entorno de Git limpio. Si existen archivos sin trackear, cambios no commiteados o archivos en staging, el baseline debe abortar con un error explícito.

## Pre-flight Check
```powershell
git status
```
Observar la salida para entender el estado actual del repo.

## Pasos de Ejecución

### Paso 1: Implementar función `_checkGitZero`
En `bin/antigravity_dpi.dart`, agregar la siguiente función de nivel top-level (fuera de cualquier clase):

```dart
/// Verifica que el repositorio git esté en estado "zero" (limpio).
/// Retorna null si está limpio, o un mensaje de error si está sucio.
Future<String?> _checkGitZero(String basePath) async {
  try {
    final result = await Process.run(
      'git',
      ['status', '--porcelain'],
      workingDirectory: basePath,
    );
    
    if (result.exitCode != 0) {
      return 'Git no disponible o directorio no es un repositorio.';
    }
    
    final output = (result.stdout as String).trim();
    if (output.isNotEmpty) {
      // Hay archivos modificados, sin trackear o en staging
      final lines = output.split('\n').take(5).join('\n'); // Mostrar máximo 5
      return 'Directorio Git no está limpio:\n$lines';
    }
    
    return null; // Estado limpio
  } catch (e) {
    return 'Error ejecutando git status: $e';
  }
}
```

### Paso 2: Invocar el chequeo al inicio de `_runBaseline`
Dentro de `_runBaseline`, como PRIMER check (incluso antes del SHS):

```dart
Future<void> _runBaseline(String basePath, String message) async {
  print('=== [GOV] STRATEGIC BASELINE SEAL ===');
  
  // GIT-ZERO CHECK: El entorno debe estar completamente limpio
  final gitError = await _checkGitZero(basePath);
  if (gitError != null) {
    print('[BLOCKED] GIT-ZERO VIOLATION: $gitError');
    print('[INFO] Commitea o stashea los cambios pendientes antes de sellar.');
    exit(1);
  }
  print('[OK] Git-Zero: Entorno limpio.');
  
  // ... resto del método (SHS check, desafío RSA, etc.)
}
```

### Paso 3: Asegurar que `Process` está importado
Verificar que `dart:io` está importado al inicio del archivo (ya debería estar):
```dart
import 'dart:io';
```

## Criterio de Éxito
- `dart analyze` → 0 errores.
- Con archivos modificados sin commitear: `dart bin/antigravity_dpi.dart baseline "Test"` → imprime `[BLOCKED] GIT-ZERO VIOLATION` y termina con exit code 1.
- Con repositorio limpio (`git status` vacío): el baseline continúa normalmente hacia el desafío RSA.

## Criterio de Fallo (DETENER si ocurre)
- El baseline procede aunque `git status` tenga salida.
- El motor llama a `Process.run` con un comando distinto a `git`.
- `dart analyze` reporta errores.
