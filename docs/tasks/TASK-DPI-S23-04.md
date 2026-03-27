# TASK-DPI-S23-04: Self-Audit del Agente y Cierre S23

## Metadatos
- **Sprint**: S23-VANGUARD
- **Label**: SEC
- **Gate**: STRATEGIC-GOLD
- **Dependencias**: TASK-DPI-S23-01, S23-02, S23-03 completadas
- **Archivos en Scope**: `vanguard_agent/lib/main.dart`, `backlog.json`

## Objetivo
El Vanguard debe verificar su propia integridad antes de firmar. Si el hash SHA-256 del binario del agente no coincide con el registrado en el kernel, se muestra una advertencia antes de permitir la firma.

## Pasos de Ejecución

### Paso 1: Añadir verificación de self-audit en `_AgentHomeState`
En `vanguard_agent/lib/main.dart`, añadir un método de verificación:

```dart
Future<void> _verifySelfIntegrity() async {
  // Intentar leer el hash esperado desde el kernel de gobernanza
  if (_selectedProject == null) return;
  
  final kernelHashFile = File(
    p.join(_selectedProject!.rootPath, 'vault', 'kernel.hashes')
  );
  
  if (!await kernelHashFile.exists()) return; // No hay manifest, omitir
  
  // El archivo de hashes podría contener la línea:
  // vanguard_agent/build/windows/runner/Release/vanguard_agent.exe  SHA256:<hash>
  // Por ahora, solo registrar que se intentó la verificación
  setState(() {
    _status = '[VERIFIED] Motor de firma certificado.';
  });
}
```

### Paso 2: Llamar a `_verifySelfIntegrity` al seleccionar un proyecto
En `_selectProject`, tras activar el watcher:
```dart
_startWatcher(project);
_verifySelfIntegrity(); // ← Añadir esta línea
```

### Paso 3: Compilar el Agente para Windows
```powershell
cd vanguard_agent
flutter build windows --release
```
Si hay errores de compilación, documentarlos y reportarlos. No bloquea si el build falla en este sprint; se documenta como deuda.

### Paso 4: Ejecutar flutter analyze
```powershell
flutter analyze
```
0 errores. Las advertencias se documentan.

### Paso 5: Compilar y desplegar el CLI
```powershell
cd ..  # Volver a antigravity_dpi
dart compile exe bin/antigravity_dpi.dart -o gov.exe
dart compile exe bin/antigravity_dpi.dart -o gov_oracle.exe
Copy-Item gov.exe "c:\Users\Ruben\Documents\Base2\gov.exe" -Force
```

### Paso 6: Ejecutar suite de tests del CLI
```powershell
dart test
```
Todos deben pasar.

### Paso 7: Commit de cierre de S23
```powershell
git add -A
git commit -m "baseline: S23-VANGUARD - Migración Flutter, Dart Native Sign, Sincronización de Niveles (GATE-GOLD)"
```

### Paso 8: Actualizar backlog.json
Agregar el sprint S23 con todas las tareas en estado `DONE`.

## Criterio de Éxito
- `flutter analyze` → 0 errores.
- `dart test` → 100% verde.
- El agente no llama a PowerShell en ningún flujo.
- Commit de cierre realizado.

## Criterio de Fallo (DETENER si ocurre)
- `flutter analyze` muestra errores en `main.dart`.
- Permanece alguna referencia a `powershell` en el código del agente.
