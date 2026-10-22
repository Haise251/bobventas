@echo off
REM Firma rapida del exe de Windows (certificado auto-firmado).
REM Uso: firmar_windows.bat "build\windows\x64\runner\Release\bob_ventas.exe" mipassword
set EXE=%1
set PASS=%2
if "%EXE%"=="" (
    echo Uso: firmar_windows.bat "ruta\al\bob_ventas.exe" contrasena
    pause
    exit /b 1
)
if "%PASS%"=="" set PASS=bob2026
powershell -ExecutionPolicy Bypass -File "%~dp0firmar_windows.ps1" -ExePath "%EXE%" -PfxPassword "%PASS%"
pause
