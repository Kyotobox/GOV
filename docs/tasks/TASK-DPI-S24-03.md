# TASK-DPI-S24-03: Cooldown Temporal para BLACK-GATE (1 hora)

## Metadatos
- **Sprint**: S24-BLACKGATE
- **Label**: GOV
- **Gate**: STRATEGIC-GOLD
- **Dependencias**: TASK-DPI-S24-01 completada
- **Archivos en Scope**: `bin/antigravity_dpi.dart`, `vault/intel/`

## Objetivo
Tras un sellado exitoso de nivel `BLACK-GATE`, el motor debe bloquear cualquier nuevo intento de `baseline` sobre los mismos archivos de núcleo durante **1 hora**. Esto rompe la inercia de sesión y obliga a una revisión en frío.

## Pasos de Ejecución

### Paso 1: Escribir el timestamp de cooldown al completar un BLACK-GATE baseline
En `_runBaseline`, justo después de confirmar que la firma fue exitosa:

```dart
// Si el nivel fue BLACK-GATE, registrar el cooldown
if (challengeId.startsWith('CORE-CHANGE-')) {
  final cooldownFile = File(p.join(basePath, 'vault', 'intel', 'blackgate_cooldown.json'));
  await cooldownFile.writeAsString(jsonEncode({
    'sealed_at': DateTime.now().toIso8601String(),
    'expires_at': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    'challenge': challengeId,
  }));
  print('[BLACK-GATE] Cooldown de 1h activado. Próximo cambio de núcleo permitido en: '
    '${DateTime.now().add(const Duration(hours: 1)).toLocal()}');
}
```

### Paso 2: Verificar el cooldown al inicio de `issueChallenge`
Al inicio del método `issueChallenge`, antes de generar el desafío:

```dart
// Verificar si hay un cooldown activo de BLACK-GATE
final cooldownFile = File(p.join(basePath, 'vault', 'intel', 'blackgate_cooldown.json'));
if (await cooldownFile.exists()) {
  try {
    final data = jsonDecode(await cooldownFile.readAsString());
    final expiresAt = DateTime.parse(data['expires_at'] as String);
    
    if (DateTime.now().isBefore(expiresAt)) {
      final remaining = expiresAt.difference(DateTime.now());
      final minutes = remaining.inMinutes;
      
      print('[BLOCKED] BLACK-GATE COOLDOWN ACTIVO.');
      print('[INFO] Cambios en el núcleo bloqueados por $minutes minutos más.');
      print('[INFO] Expiración: ${expiresAt.toLocal()}');
      exit(1);
    } else {
      // Cooldown expirado, eliminar el archivo
      await cooldownFile.delete();
    }
  } catch (_) {
    // Archivo corrupto, ignorar cooldown
    await cooldownFile.delete();
  }
}
```

### Paso 3: Añadir a `.gitignore`
El archivo de cooldown es temporal y no debe commitearse:
```
vault/intel/blackgate_cooldown.json
```

## Criterio de Éxito
- Después de un baseline BLACK-GATE exitoso, intentar otro `baseline` inmediatamente → bloqueado con `[BLOCKED] BLACK-GATE COOLDOWN ACTIVO`.
- Pasada 1 hora (o modificando manualmente el timestamp para testing), el baseline procede normalmente.
- `dart analyze` → 0 errores.

## Criterio de Fallo (DETENER si ocurre)
- El motor permite dos sellados BLACK-GATE consecutivos sin esperar.
- El archivo `blackgate_cooldown.json` se commitea al repositorio.
