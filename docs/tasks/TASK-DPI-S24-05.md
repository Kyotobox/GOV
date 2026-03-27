# TASK-DPI-S24-05: Compilación Final, Tests y Cierre de S24

## Metadatos
- **Sprint**: S24-BLACKGATE
- **Label**: OPS
- **Gate**: STRATEGIC-GOLD (Requiere firma RSA del PO)
- **Dependencias**: TASK-DPI-S24-01, S24-02, S24-03, S24-04 completadas
- **Archivos en Scope**: `gov.exe`, `gov_oracle.exe`, `backlog.json`

## Objetivo
Compilar el binario final con todas las características de S24, verificar el sistema completo, actualizar el backlog y realizar el commit de cierre sellado con el Agente Vanguard.

## Pasos de Ejecución

### Paso 1: Suite completa de tests del CLI
```powershell
dart test
```
100% verde obligatorio.

### Paso 2: Análisis estático del CLI
```powershell
dart analyze
```
0 errores.

### Paso 3: Análisis estático del Agente Vanguard
```powershell
cd vanguard_agent
flutter analyze
cd ..
```
0 errores.

### Paso 4: Prueba de sistema completa
```powershell
# Test 1: Audit estándar
dart bin/antigravity_dpi.dart audit

# Test 2: Tamper simulation
dart bin/antigravity_dpi.dart audit --simulate-tamper

# Test 3: Verificar que el baseline con git dirty falla
echo "test" > test_dirty.txt
dart bin/antigravity_dpi.dart baseline "Dirty Test"
# Debe bloquearse con GIT-ZERO VIOLATION
Remove-Item test_dirty.txt

# Test 4: Verificar SHS auto-lock
# (Crear archivos temporales hasta superar 15 en raíz y verificar bloqueo)
```

### Paso 5: Compilar los binarios finales
```powershell
dart compile exe bin/antigravity_dpi.dart -o gov.exe
dart compile exe bin/antigravity_dpi.dart -o gov_oracle.exe
```

### Paso 6: Desplegar en Base2
```powershell
Copy-Item gov.exe "c:\Users\Ruben\Documents\Base2\gov.exe" -Force
```

### Paso 7: Verificar gov.exe en Base2
```powershell
& "c:\Users\Ruben\Documents\Base2\gov.exe" audit
```

### Paso 8: Preparar el commit de cierre (GATE-GOLD)
```powershell
git add -A
git status  # Revisar qué se va a commitear — confirmación visual obligatoria
```

### Paso 9: Solicitar el baseline GOLD para el commit de cierre
```powershell
dart bin/antigravity_dpi.dart baseline "S24-BLACKGATE Final Seal"
```
El Agente Vanguard debe activarse para firmar. **El PO debe revisar el nivel del desafío antes de firmar**.

### Paso 10: Commit de cierre (después de la firma)
```powershell
git commit -m "baseline: S24-BLACKGATE - BLACK-GATE Friction, Cooldown, Recovery Seed (GATE-GOLD)"
```

### Paso 11: Actualizar backlog.json
Agregar los sprints S21, S22, S23 y S24 en estado `DONE` si no fueron actualizados en sus respectivos cierres.

## Criterio de Éxito
- `dart test` → 100% verde.
- `dart analyze` → 0 errores.
- `flutter analyze` → 0 errores.
- Git-Zero bloquea correctamente.
- SHS auto-lock funciona en > 90%.
- BLACK-GATE cooldown activo tras primer sellado.
- RECOVERY-SEED generado e impreso.
- Commit de cierre realizado con firma RSA del PO.

## Criterio de Fallo (DETENER si ocurre)
- Cualquier test en rojo.
- El baseline no requiere intervención del Agente Vanguard.
- El commit se realiza sin que el Agente haya firmado.
