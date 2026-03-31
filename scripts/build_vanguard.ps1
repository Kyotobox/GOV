# SCRIPT DE CONSTRUCCIÓN Y DESPLIEGUE (v8.2.0) [DPI-GATE-GOLD]
$ProjectRoot = "c:\Users\Ruben\Documents\antigravity_dpi"
$BunkerPath = "$ProjectRoot\vanguard_agent"
$DestPath = "c:\Users\Ruben\Documents\Base2\bin"

Write-Host "=== [GOV] INICIANDO COMPILACIÓN DUAL v8.2.0 ===" -ForegroundColor Cyan

# 1. Compilación del Kernel (antigravity_dpi)
Write-Host "Compilando Kernel (gov.dart)..." -ForegroundColor Yellow
Push-Location $ProjectRoot
dart compile exe bin/antigravity_dpi.dart -o bin/gov.exe
if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] Error en Kernel." -ForegroundColor Red; exit 1 }
Pop-Location

# 2. Compilación del Agente (Vanguard)
if (-not (Test-Path $BunkerPath)) {
    Write-Host "[ERROR] No se encuentra el búnker: $BunkerPath" -ForegroundColor Red
    exit 1
}

Push-Location $BunkerPath
Write-Host "Limpiando y preparando entorno Agente..." -ForegroundColor Yellow
flutter clean
flutter pub get

Write-Host "Compilando Vanguard Agent (Release)..." -ForegroundColor Yellow
flutter build windows --release

$BinaryPath = "$BunkerPath\build\windows\x64\runner\Release\vanguard_agent.exe"

if (Test-Path $BinaryPath) {
    Write-Host "[OK] Compilación exitosa del Agente." -ForegroundColor Green
    if (-not (Test-Path $DestPath)) { New-Item -ItemType Directory -Path $DestPath }
    
    # Replicación
    Copy-Item "$ProjectRoot\bin\gov.exe" -Destination "$DestPath\gov.exe" -Force
    Copy-Item $BinaryPath -Destination "$DestPath\vanguard.exe" -Force
    
    # DLLs y Dependencias
    Get-ChildItem "$BunkerPath\build\windows\x64\runner\Release\*.dll" | ForEach-Object {
        Copy-Item $_.FullName -Destination $DestPath -Force
    }
    
    Write-Host "[SUCCESS] Vanguard v8.2.0 + Kernel Inyectados en $DestPath" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Error crítico en la compilación del Agente." -ForegroundColor Red
}

Pop-Location
Write-Host "=== [GOV] FIN DEL PROCEDIMIENTO v8.2.0 ===" -ForegroundColor Cyan
