# TASK-DPI-S25-05: Corregir Wizards DPI-INIT y DPI-ADOPT

## Contexto
Ambos wizards (`DpiInitWizardScreen` y `DpiAdoptWizardScreen`) tienen defectos críticos:

**DPI-INIT**:
1. Usa `Directory.current.path` como `basePath` del Kernel — incorrecto cuando el proceso
   de Vanguard se lanza desde otro directorio. Debe usar la ruta del Oráculo (antigravity_dpi).
2. No registra el nuevo búnker en `fleet_registry.json` — el proyecto creado queda invisible en Vanguard.

**DPI-ADOPT**:  
1. Mismo problema con `Directory.current.path`.
2. La pantalla de "Escaneo" llama a `gov adopt` inmediatamente, pero `gov adopt` ya MODIFICA el disco
   (inyecta binarios, genera backlog). Se debe separar en dos fases:
   - **Escaneo**: `gov adopt <path> --dry-run` → solo diagnóstica
   - **Adopción**: `gov adopt <path> --commit` → ejecuta los cambios
3. No ofrece botón "ADOPTAR" después del scan.

## Archivos a Modificar
1. `vanguard_agent/lib/features/dpi_init/dpi_init_wizard_screen.dart`
2. `vanguard_agent/lib/features/dpi_adopt/dpi_adopt_wizard_screen.dart`
3. `vanguard_agent/lib/services/governance_service.dart`

## Parte A: Corrección del Kernel Path

### Problema
```dart
// INCORRECTO (actual):
final result = await service.runGov(Directory.current.path, ['init', ...]);
```

### Solución
Agregar a `GovernanceService` un método para obtener la ruta del Kernel:

En `governance_service.dart`:
```dart
// [S25-05] Obtener ruta del Oráculo (antigravity_dpi)
String getOracleRoot() {
  // Primero intentar desde executable path
  final exePath = Platform.resolvedExecutable;
  final exeDir = File(exePath).parent;
  // Si gov.exe está en bin/, el root es el padre
  if (p.basename(exeDir.path) == 'bin') {
    return exeDir.parent.path;
  }
  return exeDir.path;
}
```

En ambos wizards, reemplazar:
```dart
// ANTES:
await service.runGov(Directory.current.path, [...]);
// DESPUÉS:
await service.runGov(service.getOracleRoot(), [...]);
```

## Parte B: DPI-INIT — Registro post-creación en Fleet

En `_runInit()`, después de `result.exitCode == 0`, agregar:

```dart
if (result.exitCode == 0) {
  // [S25-05] Registrar el nuevo búnker en fleet_registry.json
  await service.registerInFleet(
    oracleRoot: service.getOracleRoot(),
    projectName: _nameController.text.trim(),
    projectPath: _pathController.text.trim(),
  );
  setState(() => _successMessage = "Búnker '$projectName' instanciado y registrado en la flota.");
}
```

Agregar en `GovernanceService`:
```dart
Future<void> registerInFleet({required String oracleRoot, required String projectName, required String projectPath}) async {
  final registryFile = File(p.join(oracleRoot, 'vault', 'intel', 'fleet_registry.json'));
  Map<String, dynamic> registry = {"bunkers": []};
  if (await registryFile.exists()) {
    try { registry = jsonDecode(await registryFile.readAsString()); } catch (_) {}
  }
  final bunkers = (registry['bunkers'] ?? registry['projects'] ?? []) as List;
  if (!bunkers.any((b) => b['path'] == projectPath)) {
    bunkers.add({
      "name": projectName,
      "path": projectPath,
      "status": "ACTIVE",
      "adopted_at": DateTime.now().toIso8601String(),
    });
    registry['bunkers'] = bunkers;
    await registryFile.writeAsString(JsonEncoder.withIndent('  ').convert(registry));
  }
}
```

## Parte C: DPI-ADOPT — Separar Scan de Commit

### Nuevo Flujo del Wizard (3 pasos → 4 pasos)
```
PASO 1: Selección de ruta
PASO 2: [ESCANEO] — gov adopt <path> --dry-run  ← NUEVO
PASO 3: Resultados del scan + Score de Alineación
PASO 4: [ADOPTAR] — gov adopt <path> --commit   ← NUEVO
```

### Implementar `--dry-run` en gov.dart

En `runAdopt()`, al inicio:
```dart
Future<void> runAdopt(String basePath, List<String> args) async {
  final isDryRun = args.contains('--dry-run');
  final isCommit = args.contains('--commit');
  // ...

  // Si es --dry-run: solo diagnosticar y retornar JSON con gaps, NO modificar nada
  if (isDryRun) {
    // Calcular gaps sin escribir ningún archivo
    final diagOutput = {
      "gaps": gaps.map((g) => g['id']).toList(),
      "score": ((1 - gaps.length / 5.0) * 100).toInt().clamp(0, 100),
      "target": targetPath,
    };
    print(JsonEncoder.withIndent('  ').convert(diagOutput));
    return; // SALIR sin modificar el sistema de archivos
  }

  // Si es --commit: ejecutar la adopción completa (lógica actual)
  // Si no hay flag: comportamiento legacy (adopción inmediata) — mantener para compatibilidad
```

### En el Wizard DPI-ADOPT

Actualizar `_runScan()` para usar `--dry-run`:
```dart
Future<void> _runScan() async {
  // ...
  final result = await service.runGov(
    service.getOracleRoot(),
    ['adopt', targetPath, '--dry-run'], // [S25-05] Solo diagnóstico
  );

  if (result.exitCode == 0) {
    final diagData = jsonDecode(result.stdout);
    // Actualizar _checkMap desde el JSON de diagnóstico
    // Mostrar _score desde diagData['score']
    setState(() { _currentStep = 2; }); // Ir a step de resultados
  }
}
```

Agregar botón en el paso de resultados:
```dart
// En el Step de RESULTADOS, agregar botón ADOPTAR:
ElevatedButton(
  onPressed: _isAdopting ? null : _runAdopt,
  style: ElevatedButton.styleFrom(
    backgroundColor: _score >= 60 ? Colors.orangeAccent : Colors.redAccent,
    foregroundColor: Colors.black,
  ),
  child: Text(_isAdopting ? 'ADOPTANDO...' : 'ADOPTAR PROYECTO (--commit)'),
),
```

```dart
Future<void> _runAdopt() async {
  setState(() => _isAdopting = true);
  try {
    final result = await service.runGov(
      service.getOracleRoot(),
      ['adopt', _pathController.text.trim(), '--commit'],
    );
    if (result.exitCode == 0) {
      await service.registerInFleet(
        oracleRoot: service.getOracleRoot(),
        projectName: p.basename(_pathController.text.trim()),
        projectPath: _pathController.text.trim(),
      );
      setState(() => _currentStep = 3); // Paso de éxito
    }
  } finally {
    setState(() => _isAdopting = false);
  }
}
```

## Criterios de Aceptación
- [ ] DPI-INIT con rutas hardcodeadas eliminadas — usa `service.getOracleRoot()`
- [ ] DPI-INIT: proyecto creado aparece en `fleet_registry.json` y sidebar de Vanguard
- [ ] DPI-ADOPT: ESCANEO no modifica ningún archivo (dry-run)
- [ ] DPI-ADOPT: botón ADOPTAR aparece después del scan con el score
- [ ] DPI-ADOPT: tras ADOPTAR, el proyecto aparece en la sidebar de Vanguard

## Restricciones (NO HACER)
- NO romper la compatibilidad de `gov adopt <path>` sin flags (mantener comportamiento legacy)
- NO fusionar _runScan y _runAdopt en un solo paso
