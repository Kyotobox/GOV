# TASK-DPI-S22-03: Cierre, Tests y Commit de S22

## Metadatos
- **Sprint**: S22-LEDGER
- **Label**: QA
- **Gate**: OPERATIONAL-RED
- **Dependencias**: TASK-DPI-S22-01 y S22-02 completadas
- **Archivos en Scope**: `gov.exe`, `backlog.json`

## Pasos de Ejecución

### Paso 1: Ejecutar suite completa de tests
```powershell
dart test
```
Todos los tests, incluyendo el nuevo `test/ledger_chain_test.dart`, deben pasar.

### Paso 2: Verificación manual de cadena rota
```powershell
# 1. Ejecutar un handover para generar entradas en el ledger
dart bin/antigravity_dpi.dart handover

# 2. Abrir HISTORY.md y modificar manualmente UNA entrada
# (añadir un carácter cualquiera)

# 3. Verificar que audit detecta la ruptura
dart bin/antigravity_dpi.dart audit
```
Debe imprimirse `[CRITICAL] LEDGER CHAIN BROKEN`.

### Paso 3: Verificación del Relay
```powershell
dart bin/antigravity_dpi.dart handover
dart bin/antigravity_dpi.dart takeover
```
El takeover debe mostrar el GitHash del relay anterior.

### Paso 4: Compilar y desplegar
```powershell
dart compile exe bin/antigravity_dpi.dart -o gov.exe
Copy-Item gov.exe "c:\Users\Ruben\Documents\Base2\gov.exe" -Force
```

### Paso 5: Commit de cierre
```powershell
git add -A
git commit -m "baseline: S22-LEDGER - Chain of Trust y Relay Atómico (GATE-RED)"
```

### Paso 6: Actualizar backlog.json
Agregar el sprint S22 con todas sus tareas en estado `DONE`.

## Criterio de Éxito
- `dart test` → 100% verde.
- Ledger alterado manualmente → `audit` entra en PANIC.
- `handover` + `takeover` → GitHash visible en consola.
- Commit realizado.
