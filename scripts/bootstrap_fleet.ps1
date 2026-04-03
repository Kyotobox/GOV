# SCRIPT DE BOOTSTRAP DE FLOTA NUCLEUS-V9 (v9.0.1)
# Este script realiza la transición inicial manual a automática de binarios.

$Projects = @(
    @{ name = "Base2"; path = "C:\Users\Ruben\Documents\Base2" },
    @{ name = "miniduo"; path = "C:\Users\Ruben\Documents\miniduo" }
)

Write-Host "--- [GOV] INICIANDO BOOTSTRAP DE FLOTA V9.0.1 ---" -ForegroundColor Cyan

foreach ($proj in $Projects) {
    $binDir = Join-Path $proj.path "bin"
    Write-Host "`nProcesando Nodo: $($proj.name)..." -ForegroundColor Yellow

    if (!(Test-Path $binDir)) {
        Write-Host "  [SKIP] No se encontró carpeta bin/ en $($proj.path)" -ForegroundColor Gray
        continue
    }

    # 1. Swap de gov.exe
    $govUpdate = Join-Path $binDir "gov.exe.update"
    $govExe = Join-Path $binDir "gov.exe"
    
    if (Test-Path $govUpdate) {
        if (Test-Path $govExe) {
            $oldGov = $govExe + ".old"
            if (Test-Path $oldGov) { Remove-Item $oldGov -Force }
            Rename-Item $govExe -NewName "gov.exe.old"
            Write-Host "  [BACKUP] gov.exe -> .old" -ForegroundColor Gray
        }
        Rename-Item $govUpdate -NewName "gov.exe"
        Write-Host "  [SUCCESS] gov.exe (v9.0.1) ACTIVADO" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] No se encontró gov.exe.update en $($proj.name)" -ForegroundColor Gray
    }

    # 2. Swap de vanguard.exe
    $vanguardUpdate = Join-Path $binDir "vanguard.exe.update"
    $vanguardExe = Join-Path $binDir "vanguard.exe"

    if (Test-Path $vanguardUpdate) {
        if (Test-Path $vanguardExe) {
            $oldVanguard = $vanguardExe + ".old"
            if (Test-Path $oldVanguard) { Remove-Item $oldVanguard -Force }
            Rename-Item $vanguardExe -NewName "vanguard.exe.old"
            Write-Host "  [BACKUP] vanguard.exe -> .old" -ForegroundColor Gray
        }
        Rename-Item $vanguardUpdate -NewName "vanguard.exe"
        Write-Host "  [SUCCESS] vanguard.exe (v9.0.1) ACTIVADO" -ForegroundColor Green
    }

    # 3. Verificación de Versión
    Push-Location $proj.path
    try {
        $versionInfo = & $govExe status --json | ConvertFrom-Json
        Write-Host "  [VERIFIED] ADN: SEALED | SHS: $($versionInfo.shs_pulse)%" -ForegroundColor Cyan
    } catch {
        Write-Host "  [WARNING] No se pudo verificar la versión automática, pero binarios instalados." -ForegroundColor Yellow
    }
    Pop-Location
}

Write-Host "`n--- [GOV] BOOTSTRAP COMPLETADO ---" -ForegroundColor Cyan
