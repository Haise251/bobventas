@echo off
REM ============================================================
REM  Genera el keystore de firma para la app Bob Ventas (Android)
REM  Requisito: tener JDK instalado (incluye la herramienta keytool)
REM  Resultado: android\app\bob-ventas-key.jks
REM ============================================================
echo.
echo === Generador de keystore para Bob Ventas ===
echo.

set KEYSTORE=android\app\bob-ventas-key.jks
set ALIAS=bob-ventas-key

if exist "%KEYSTORE%" (
    echo [AVISO] El keystore %KEYSTORE% ya existe.
    set /p OVERWRITE="Escribe SI para reemplazarlo (las firmas anteriores dejaran de ser validas para Google Play): "
    if /I not "%OVERWRITE%"=="SI" (
        echo Cancelado.
        pause
        exit /b 0
    )
    del "%KEYSTORE%"
)

echo Se te pediran:
echo   1. Dos contrasenas ^(usa la misma en ambas y guardala bien^)
echo   2. Nombre y organizacion ^^(puedes poner "Bob Burguer"^)
echo   3. Unidad de organizacion, ciudad, estado y pais ^^(VE para Venezuela^)
echo.

keytool -genkeypair -v ^
    -keystore "%KEYSTORE%" ^
    -alias %ALIAS% ^
    -keyalg RSA -keysize 2048 -validity 10000

if errorlevel 1 (
    echo.
    echo [ERROR] No se encontro keytool. Instala el JDK ^(o Android Studio^)
    echo         y asegurate de que este en el PATH.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  Keystore creado: %KEYSTORE%
echo.
echo  Siguiente paso: copia android\key.properties.example como
echo  android\key.properties y escribe tus contrasenas:
echo    storePassword=...
echo    keyPassword=...
echo    keyAlias=%ALIAS%
echo    storeFile=../app/bob-ventas-key.jks
echo.
echo  Luego compila con:  flutter build apk --release
echo ============================================================
pause
