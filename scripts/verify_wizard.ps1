# SCRIPT DE CERTIFICACION QA (S120-FLEET) - v6.7.3
# Este script valida el ecosistema dual (Kernel [Dart] + HU [Flutter]).
# Se han eliminado caracteres especiales para evitar errores de codificacion.

$RootBunker = "c:\Users\Ruben\Documents\antigravity_dpi"
$UIVanguard = "$RootBunker\vanguard_agent"

Write-Host "--- [GOV] INICIANDO CERTIFICACION DUAL ---" -ForegroundColor Cyan

# 1. Certificacion del Kernel (Logica cov init - Pure Dart)
Write-Host "1. Certificando Logica del Kernel: gov_init_test..." -ForegroundColor Yellow
$KernelTest = "$RootBunker\test\src\kernel\gov_init_test.dart"
if (Test-Path $KernelTest) {
    Push-Location $RootBunker
    Write-Host "Sincronizando dependencias del Kernel..." -ForegroundColor Gray
    dart pub get
    dart test $KernelTest
    if ($LASTEXITCODE -eq 0) { Write-Host "[OK] Kernel Verificado." -ForegroundColor Green }
    else { Write-Host "[FAIL] Fallo en Logica del Kernel." -ForegroundColor Red; exit 1 }
    Pop-Location
}

# 2. Certificacion de la Interfaz (Wizard UI - Flutter)
Write-Host "2. Certificando Simulacion UI: init_wizard_sim_test..." -ForegroundColor Yellow
$UITest = "$UIVanguard\test\simulation\init_wizard_sim_test.dart"
if (Test-Path $UITest) {
    Push-Location $UIVanguard
    # No hace falta flutter pub get aqui (ya se hizo en build_vanguard o previos)
    flutter test $UITest
    if ($LASTEXITCODE -eq 0) { Write-Host "[OK] Simulacion UI Exitosa." -ForegroundColor Green }
    else { Write-Host "[FAIL] Fallo en UI." -ForegroundColor Red; exit 1 }
    Pop-Location
}

Write-Host "--- [GOV] CERTIFICACION COMPLETADA ---" -ForegroundColor Cyan
