@echo off
echo Configurando adb reverse para backend local...
adb reverse tcp:3000 tcp:3000 2>nul
if %errorlevel% neq 0 (
    echo adb no encontrado en PATH, buscando en ubicaciones comunes...
    if exist "C:\Android\platform-tools\adb.exe" (
        C:\Android\platform-tools\adb.exe reverse tcp:3000 tcp:3000
    ) else if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
        "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" reverse tcp:3000 tcp:3000
    ) else (
        echo ERROR: No se encontro adb. Asegurate de tener Android SDK instalado.
        pause
        exit /b 1
    )
)
echo Listo. localhost:3000 del telefono apunta a tu PC.
echo.
echo Iniciando Flutter...
flutter run
