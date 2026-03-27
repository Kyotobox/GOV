# TASK-DPI-S23-01: Migración Atómica del Vanguard Agent

## Metadatos
- **Sprint**: S23-VANGUARD
- **Label**: ARCH
- **Gate**: STRATEGIC-GOLD
- **Dependencias**: S21 y S22 completados. Requiere firma RSA del PO para proceder.
- **Archivos en Scope**: `vanguard_agent/` (nueva carpeta en antigravity_dpi)

## Objetivo
Copiar el código fuente del Agente Vanguard desde `Base2/vanguard_agent/` al Kernel de Gobernanza `antigravity_dpi/vanguard_agent/`. La operación es atómica: se copia todo sin modificar nada todavía.

## ⚠️ Advertencia de Nivel
Esta tarea pertenece al nivel **STRATEGIC-GOLD**. Solo iniciar si el Agente Vanguard puede ser usado para firmar el baseline de este sprint.

## Pre-flight Check
```powershell
# Verificar que el origen existe
ls "c:\Users\Ruben\Documents\Base2\vanguard_agent\lib\main.dart"

# Verificar que el destino NO existe aún
ls "c:\Users\Ruben\Documents\antigravity_dpi\vanguard_agent" -ErrorAction SilentlyContinue
```
Si el destino ya existe, detener y reportar.

## Pasos de Ejecución

### Paso 1: Copiar el directorio completo
```powershell
Copy-Item "c:\Users\Ruben\Documents\Base2\vanguard_agent" `
  "c:\Users\Ruben\Documents\antigravity_dpi\vanguard_agent" `
  -Recurse -Force
```

### Paso 2: Eliminar artefactos de build del destino
```powershell
Remove-Item "c:\Users\Ruben\Documents\antigravity_dpi\vanguard_agent\build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "c:\Users\Ruben\Documents\antigravity_dpi\vanguard_agent\.dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
```

### Paso 3: Verificar estructura crítica del destino
```powershell
ls "c:\Users\Ruben\Documents\antigravity_dpi\vanguard_agent\lib\main.dart"
cat "c:\Users\Ruben\Documents\antigravity_dpi\vanguard_agent\pubspec.yaml"
```

### Paso 4: Añadir `vanguard_agent/` al `.gitignore` correctamente
Abrir el `.gitignore` raíz de `antigravity_dpi` y verificar que `build/` esté excluido globalmente. Si no, agregar:
```
# Vanguard Agent builds
vanguard_agent/build/
vanguard_agent/.dart_tool/
```

### Paso 5: Verificar dependencias del agente
```powershell
cd vanguard_agent
flutter pub get
```
Si falla, documentar el error y continuar con TASK-DPI-S23-02 para resolverlo.

## Criterio de Éxito
- `c:\Users\Ruben\Documents\antigravity_dpi\vanguard_agent\lib\main.dart` existe.
- `flutter pub get` ejecuta sin errores.
- Los directorios `build/` y `.dart_tool/` NO están en el commit.

## Criterio de Fallo (DETENER si ocurre)
- La copia falla parcialmente.
- La carpeta `Base2/vanguard_agent/` tiene modificaciones no commiteadas antes de copiar.
