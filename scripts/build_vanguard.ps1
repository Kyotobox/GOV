# SCRIPT DE CONSTRUCCIÓN Y DESPLIEGUE (v7.0)
$BunkerPath = "c:\Users\Ruben\Documents\antigravity_dpi\vanguard_agent"
$DestPath = "c:\Users\Ruben\Documents\Base2\bin"

Write-Host "=== [GOV] INICIANDO COMPILACIÓN ELITE 7.0 ===" -ForegroundColor Cyan

if (-not (Test-Path $BunkerPath)) {
    Write-Host "[ERROR] No se encuentra el búnker: $BunkerPath" -ForegroundColor Red
    exit 1
}

Push-Location $BunkerPath
Write-Host "Limpiando y preparando entorno..." -ForegroundColor Yellow
flutter clean
flutter pub get

Write-Host "Compilando Vanguard Agent (Release)..." -ForegroundColor Yellow
flutter build windows --release

$BinaryPath = "$BunkerPath\build\windows\x64\runner\Release\vanguard_agent.exe"

if (Test-Path $BinaryPath) {
    Write-Host "[OK] Compilación exitosa." -ForegroundColor Green
    if (-not (Test-Path $DestPath)) { New-Item -ItemType Directory -Path $DestPath }
    
    Copy-Item $BinaryPath -Destination "$DestPath\vanguard.exe" -Force
    
    # DLLs
    Get-ChildItem "$BunkerPath\build\windows\x64\runner\Release\*.dll" | ForEach-Object {
        Copy-Item $_.FullName -Destination $DestPath -Force
    }
    
    Write-Host "[SUCCESS] Vanguard Elite 7.0 Inyectado en $DestPath" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Error crítico en la compilación." -ForegroundColor Red
}

Pop-Location
Write-Host "=== [GOV] FIN DEL PROCEDIMIENTO 7.0 ===" -ForegroundColor Cyan
