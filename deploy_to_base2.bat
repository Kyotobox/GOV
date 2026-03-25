@echo off 
echo Compilando binario AOT (gov.exe)... 
call dart compile exe bin/antigravity_dpi.dart -o gov.exe 
echo Desplegando a Base2... 
copy /Y gov.exe "C:\Users\Ruben\Documents\Base2\gov.exe" 
echo [OK] Despliegue completado con exito. 
pause 
