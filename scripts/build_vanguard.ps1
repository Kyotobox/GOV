# SCRIPT DE CONSTRUCCION Y DESPLIEGUE EN CASCADA (v9.1.0 SENTINEL) [DPI-GATE-GOLD]
# Protocol: NUCLEUS-V9 Hot-Swap Certification.

$ProjectRoot = "c:\Users\Ruben\Documents\antigravity_dpi"
$BunkerPath = "$ProjectRoot\vanguard_agent"

# Flota de Destino (Project Roots)
$Destinations = @(
    "c:\Users\Ruben\Documents\Base2",
    "c:\Users\Ruben\Documents\miniduo"
)

Write-Host "=== [GOV] INICIANDO COMPILACION DUAL v9.1.0 (SENTINEL-CASCADE) ===" -ForegroundColor Cyan

# 1. Compilacion y Firma del Kernel (antigravity_dpi)
Write-Host "1/4 Compilando Kernel (gov.dart)..." -ForegroundColor Yellow
Push-Location $ProjectRoot
dart compile exe bin/antigravity_dpi.dart -o bin/gov.exe
if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] Error en Kernel." -ForegroundColor Red; Pop-Location; exit 1 }

Write-Host "Firmando Kernel para cascada..." -ForegroundColor Cyan
.\bin\gov.exe sign --file bin\gov.exe
if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] Fallo al firmar Kernel." -ForegroundColor Red; Pop-Location; exit 1 }
Pop-Location

# 2. Compilacion del Agente (Vanguard)
if (-not (Test-Path $BunkerPath)) {
    Write-Host "[ERROR] No se encuentra el bunker: $BunkerPath" -ForegroundColor Red
    exit 1
}

Push-Location $BunkerPath
Write-Host "2/4 Preparando entorno Agente (Flutter)..." -ForegroundColor Yellow
flutter clean
flutter pub get

Write-Host "Compilando Vanguard Agent (Release)..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] Error en Agente." -ForegroundColor Red; Pop-Location; exit 1 }

$BinaryPath = "$BunkerPath\build\windows\x64\runner\Release\vanguard_agent.exe"

if (Test-Path $BinaryPath) {
    Write-Host "[OK] Compilacion exitosa del Agente." -ForegroundColor Green
    
    # Firma del Agente
    Write-Host "Firmando Agente para cascada..." -ForegroundColor Cyan
    Push-Location $ProjectRoot
    .\bin\gov.exe sign --file $BinaryPath
    Pop-Location

    # 3. Propagacion en Cascada
    Write-Host "3/4 Iniciando propagacion a la flota..." -ForegroundColor Yellow
    foreach ($DestPath in $Destinations) {
        $TargetBin = Join-Path $DestPath "bin"
        $TargetVault = Join-Path $DestPath "vault"
        
        if (-not (Test-Path $TargetBin)) { New-Item -ItemType Directory -Path $TargetBin -Force }
        if (-not (Test-Path $TargetVault)) { New-Item -ItemType Directory -Path $TargetVault -Force }

        Write-Host "Replicando en: $DestPath ..." -ForegroundColor Cyan
        
        # Copia de Kernel y Sello
        Copy-Item "$ProjectRoot\bin\gov.exe" -Destination "$TargetBin\gov.exe.update" -Force
        Copy-Item "$ProjectRoot\bin\gov.exe.sig" -Destination "$TargetBin\gov.exe.update.sig" -Force
        Copy-Item "$ProjectRoot\vault\po_public.xml" -Destination "$TargetVault\po_public.xml" -Force
        
        # Copia de Agente y Sello
        Copy-Item $BinaryPath -Destination "$TargetBin\vanguard.exe.update" -Force
        Copy-Item "$BinaryPath.sig" -Destination "$TargetBin\vanguard.exe.update.sig" -Force
        
        # Replicacion de DLLs
        Get-ChildItem "$BunkerPath\build\windows\x64\runner\Release\*.dll" | ForEach-Object {
            Copy-Item $_.FullName -Destination $TargetBin -Force
        }

        # 4. UPGRADE AUTOMATICO (NUCLEUS-V9)
        Write-Host "Ejecutando UPGRADE automatico en: $DestPath ..." -ForegroundColor Yellow
        Push-Location $DestPath
        if (Test-Path "bin\gov.exe") {
            .\bin\gov.exe upgrade
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[SUCCESS] Nodo actualizado con exito." -ForegroundColor Green
            } else {
                Write-Host "[WARNING] Fallo parcial en el upgrade del nodo." -ForegroundColor Yellow
            }
        } else {
            # Si no hay gov.exe previo, lo movemos directamente (Primer despliegue)
            Move-Item "bin\gov.exe.update" "bin\gov.exe" -Force
            Move-Item "bin\vanguard.exe.update" "bin\vanguard.exe" -Force
            Write-Host "[INFO] Primer despliegue completado satisfactoriamente." -ForegroundColor Blue
        }
        Pop-Location
    }
    
    # Registro de Tarea en Log
    $LogDate = Get-Date -Format "yyyy-MM-dd HH:mm"
    $LogEntry = "- [$LogDate] [CASCADE-BUILD] Propagacion v9.1.0 SENTINEL automatizada y certificada en toda la flota."
    Add-Content -Path "$ProjectRoot\PROJECT_LOG.md" -Value $LogEntry
    
    Write-Host "[FINAL] Procedimiento de construccion y cascada finalizado con exito." -ForegroundColor Cyan
} else {
    Write-Host "[FAIL] Error critico: No se encontro el binario del Agente." -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location
Write-Host "=== [GOV] FIN DEL PROCEDIMIENTO DE CASCADA ===" -ForegroundColor Cyan
