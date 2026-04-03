# SCRIPT DE RECUPERACIÓN Y PURGA OPERATIVA (v1.0.0) [DPI-GATE-GOLD]
# Uso: .\scripts\purge.ps1 [--full]

param (
    [switch]$Full = $false
)

$ProjectRoot = "c:\Users\Ruben\Documents\antigravity_dpi"
$AgentPath = "$ProjectRoot\vanguard_agent"

Write-Host "=== [GOV] PROTOCOLO DE PURGA OPERATIVA INICIADO ===" -ForegroundColor Cyan

# 1. Terminación de Procesos Bloqueantes
Write-Host "Paso 1: Abortando procesos Dart/Flutter colgados..." -ForegroundColor Yellow
taskkill /F /IM dart.exe /T 2>$null
taskkill /F /IM flutter.exe /T 2>$null

# 2. Limpieza de Infraestructura (Operational Purity)
Write-Host "Paso 2: Eliminando artefactos de saturación..." -ForegroundColor Yellow

$PathsToClean = @(
    "$ProjectRoot\.dart_tool",
    "$ProjectRoot\build",
    "$ProjectRoot\pubspec.lock",
    "$AgentPath\.dart_tool",
    "$AgentPath\build",
    "$AgentPath\pubspec.lock"
)

foreach ($path in $PathsToClean) {
    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
        Write-Host "  [CLEAN] Eliminado: $path" -ForegroundColor Gray
    }
}

# 3. Restauración de Gobernanza (Cognitive Purity)
Write-Host "Paso 3: Ejecutando reseteo lógico de Gobernanza..." -ForegroundColor Yellow

if (Test-Path "$ProjectRoot\bin\gov.exe") {
    # Usar el binario para evitar dependencias
    & "$ProjectRoot\bin\gov.exe" housekeeping
    & "$ProjectRoot\bin\gov.exe" handover
    & "$ProjectRoot\bin\gov.exe" takeover
} else {
    # Fallback a Dart source si no hay binario
    dart bin/antigravity_dpi.dart housekeeping
    dart bin/antigravity_dpi.dart handover
    dart bin/antigravity_dpi.dart takeover
}

# 4. Sincronización (Opcional si --full)
if ($Full) {
    Write-Host "Paso 4: Reinstalando dependencias (--full)..." -ForegroundColor Yellow
    Push-Location $ProjectRoot
    dart pub get
    Set-Location vanguard_agent
    flutter pub get
    Pop-Location
}

Write-Host "=== [GOV] PURGA COMPLETADA: SISTEMA NOMINAL ===" -ForegroundColor Green
Write-Host "Verificación final con 'gov status'" -ForegroundColor Cyan
if (Test-Path "$ProjectRoot\bin\gov.exe") { & "$ProjectRoot\bin\gov.exe" status }
