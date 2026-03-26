@echo off
setlocal enabledelayedexpansion

:: ==========================================
:: GOV-FLEET-AUDIT: Orquestador Transversal
:: Sprint: S10-FLEET | Versión: 1.2.0 (FINAL)
:: ==========================================

:: CONFIGURACIÓN
set "GOV_BIN=dart C:\Users\Ruben\Documents\antigravity_dpi\bin\antigravity_dpi.dart"
set "ROOT_DIR=C:\Users\Ruben\Documents"
set "REPORT_FILE=fleet_report.txt"
set "DETAIL_LOG=fleet_details.log"
set "TMP_LIST=fleet_targets.tmp"

:: Limpiar reportes previos
echo --- FLEET AUDIT REPORT [%DATE% %TIME%] --- > "%REPORT_FILE%"
echo --- DETAILED FLEET LOG [%DATE% %TIME%] --- > "%DETAIL_LOG%"

echo [INFO] Iniciando Auditoria Transversal en: %ROOT_DIR%

:: Fase 1: Indexar directorios gobernados para evitar duplicados
if exist "%TMP_LIST%" del "%TMP_LIST%"
for /d %%D in ("%ROOT_DIR%\*") do (
    set "IS_GOV=NO"
    if exist "%%D\vault\" set "IS_GOV=YES"
    if exist "%%D\session.lock" set "IS_GOV=YES"
    
    if "!IS_GOV!"=="YES" (
        echo %%D >> "%TMP_LIST%"
    )
)

if not exist "%TMP_LIST%" (
    echo [ERROR] No se encontraron repositorios gobernados en %ROOT_DIR%
    exit /b 1
)

:: Fase 2: Procesar la lista indexada
echo [INFO] Procesando flota...
for /f "tokens=*" %%F in (%TMP_LIST%) do (
    set "TARGET_PATH=%%F"
    set "TARGET_NAME=%%~nxF"
    
    echo [AUDIT] Procesando: !TARGET_NAME!...
    
    :: Invocacion Silenciosa
    echo --- AUDIT START: !TARGET_NAME! [%TIME%] --- >> "%DETAIL_LOG%"
    
    :: Ejecucion y captura de ErrorLevel
    %GOV_BIN% --path "!TARGET_PATH!" audit >> "%DETAIL_LOG%" 2>&1
    set "AUDIT_RESULT=!errorlevel!"
    
    if !AUDIT_RESULT! equ 0 (
        echo [OK] !TARGET_NAME!
        echo [OK] !TARGET_PATH! >> "%REPORT_FILE%"
    ) else (
        echo [FAIL] !TARGET_NAME! (ERR:!AUDIT_RESULT!)
        echo [FAIL] !TARGET_PATH! >> "%REPORT_FILE%"
    )
    echo --- AUDIT END: !TARGET_NAME! --- >> "%DETAIL_LOG%"
)

:: Limpieza
if exist "%TMP_LIST%" del "%TMP_LIST%"

echo.
echo ==========================================
echo       RESUMEN DE AUDITORIA DE FLOTA
echo ==========================================
type "%REPORT_FILE%"
echo ==========================================
echo Detalles: %DETAIL_LOG%
echo ==========================================
