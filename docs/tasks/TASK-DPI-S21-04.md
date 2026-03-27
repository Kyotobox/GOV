# TASK-DPI-S21-04: Compilación, Despliegue y Cierre S21

## Metadatos
- **Sprint**: S21-RESTORE
- **Label**: OPS
- **Gate**: OPERATIONAL-RED
- **Dependencias**: TASK-DPI-S21-01, S21-02, S21-03 completadas
- **Archivos en Scope**: `gov.exe`, `c:\Users\Ruben\Documents\Base2\gov.exe`

## Objetivo
Compilar el binario final de S21, desplegarlo en Base2, ejecutar la suite de tests completa y hacer el commit de cierre de sprint.

## Pasos de Ejecución

### Paso 1: Ejecutar suite completa de tests
```powershell
dart test
```
Todos los tests deben pasar. Si alguno falla, detener y arreglar antes de continuar.

### Paso 2: Ejecutar `dart analyze`
```powershell
dart analyze
```
No deben existir errores. Las advertencias deben ser 0 o documentadas.

### Paso 3: Compilar binarios
```powershell
dart compile exe bin/antigravity_dpi.dart -o gov.exe
dart compile exe bin/antigravity_dpi.dart -o gov_oracle.exe
```
Ambos deben compilar sin errores.

### Paso 4: Desplegar en Base2
```powershell
Copy-Item gov.exe "c:\Users\Ruben\Documents\Base2\gov.exe" -Force
```

### Paso 5: Verificar audit en Base2
```powershell
& "c:\Users\Ruben\Documents\Base2\gov.exe" audit
```
Debe ejecutarse sin errores y mostrar las métricas SHS.

### Paso 6: Commit de cierre de sprint
```powershell
git add -A
git commit -m "baseline: S21-RESTORE - Purga autoSign, hardcode SHS, Git-Zero (GATE-RED)"
```

### Paso 7: Actualizar backlog.json
Añadir el sprint S21 con todas las tareas en estado `DONE` al archivo `backlog.json`.

## Criterio de Éxito
- `dart test` → 100% verde.
- `dart analyze` → 0 errores.
- `gov.exe audit` ejecuta en ambos proyectos.
- Commit realizado con el mensaje exacto especificado.
- `backlog.json` actualizado.

## Criterio de Fallo (DETENER si ocurre)
- Cualquier test en rojo.
- El binario no compila.
- `gov.exe audit` falla en Base2.
