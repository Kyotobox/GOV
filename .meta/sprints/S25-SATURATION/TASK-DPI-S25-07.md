# TASK-DPI-S25-07: Eliminar Hardcoded Paths en Vanguard

## Contexto
`main.dart` del agente Vanguard tiene 4 rutas absolutas hardcodeadas al usuario "Ruben".
Esto hace que Vanguard sea inutilizable en cualquier otra máquina o usuario.

Además, el label de versión `v8.0.0 [QUANTUM-REFORM]` en el header del dropdown está
hardcodeado en el build del widget en vez de leerse del `backlog.json` del proyecto
activo.

## Archivos a Modificar
- `vanguard_agent/lib/main.dart`

## Paths Hardcodeados a Eliminar

| Línea | Ruta hardcodeada | Solución |
|-------|-------------------|----------|
| 126 | `C:\\Users\\Ruben\\Documents\\Base2\\vault\\intel\\fleet_registry.json` | Inferir desde `getApplicationSupportDirectory()` o una variable de entorno |
| 148 | `C:\\Users\\Ruben\\Documents\\antigravity_dpi` | Inferir desde executable path |
| 160 | `C:\\Users\\Ruben\\Documents\\Base2` | Eliminar fallback hardcodeado |
| 161 | `C:\\Users\\Ruben\\Documents\\antigravity_dpi` | Eliminar fallback hardcodeado |

## Implementación Paso a Paso

### Paso 1 — Resolver la ruta del Oráculo (antigravity_dpi) dinámicamente

```dart
// [S25-07] Resolver ruta del Oráculo desde el ejecutable
String _resolveOracleRoot() {
  final exePath = Platform.resolvedExecutable;
  final exeDir = File(exePath).parent;
  // Si Vanguard.exe está en bin/, el root es el padre
  if (p.basename(exeDir.path) == 'bin') {
    return exeDir.parent.path;
  }
  // Si está en la raíz del proyecto (desarrollo)
  return exeDir.path;
}
```

### Paso 2 — Inferir fleet_registry.json dinámicamente

Reemplazar en `_loadSettings()`:
```dart
// ANTES (línea 126):
const String masterFleetPath = 'C:\\Users\\Ruben\\Documents\\Base2\\vault\\intel\\fleet_registry.json';

// DESPUÉS:
final oracleRoot = _resolveOracleRoot();
final masterFleetPath = p.join(oracleRoot, 'vault', 'intel', 'fleet_registry.json');
```

### Paso 3 — Eliminar fallback hardcodeado

Reemplazar el bloque `else` con proyectos hardcodeados:
```dart
// ANTES (líneas 158-163):
_projects = [
  Project(id: 'base2', name: 'BASE2 - LABS', rootPath: 'C:\\Users\\Ruben\\...', ...),
  Project(id: 'gov', name: 'KYOTOBOX - GOV', rootPath: 'C:\\Users\\Ruben\\...', ...)
];

// DESPUÉS:
final oracleRoot = _resolveOracleRoot();
_projects = [
  Project(id: 'gov', name: 'KYOTOBOX - GOV', rootPath: oracleRoot, keyPath: 'root')
];
// Sin más hardcoding — si no hay fleet_registry, solo mostrar el Oráculo
```

### Paso 4 — Agregar el proyecto Oráculo dinámicamente

Reemplazar (línea 148):
```dart
// ANTES:
_projects.add(Project(id: 'gov', name: 'KYOTOBOX - GOV', rootPath: 'C:\\Users\\Ruben\\Documents\\antigravity_dpi', keyPath: 'root'));

// DESPUÉS:
_projects.add(Project(id: 'gov', name: 'KYOTOBOX - GOV', rootPath: _resolveOracleRoot(), keyPath: 'root'));
```

### Paso 5 — Leer la versión dinámicamente

En `_MainHUDState`, añadir:
```dart
String _activeProjectVersion = 'v8.0.0'; // [S25-07] Valor inicial fallback
```

En `_refreshTelemetry()`, después de leer el backlog:
```dart
// [S25-07] Leer versión del backlog
final version = data['version'] ?? data['kernel_version'] ?? 'v8.0.0';
setState(() => _activeProjectVersion = version);
```

En el widget del dropdown (línea 588), reemplazar:
```dart
// ANTES:
const Text("v8.0.0 [QUANTUM-REFORM]", ...)

// DESPUÉS:
Text(_activeProjectVersion, ...)
```

## Criterios de Aceptación
- [ ] Vanguard se inicia en una máquina con username diferente a "Ruben" sin errores
- [ ] `fleet_registry.json` se encuentra automáticamente si está en la ruta estándar del Oráculo
- [ ] El label de versión en el dropdown muestra la versión del `backlog.json` del proyecto activo
- [ ] Si no hay `fleet_registry.json`, Vanguard muestra solo el proyecto "KYOTOBOX - GOV" como fallback

## Restricciones (NO HACER)
- NO usar `Platform.environment['USERNAME']` — es frágil entre OS
- NO eliminar el fallback a solo el proyecto "GOV" — es necesario para primera ejecución
