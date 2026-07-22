@echo off
setlocal EnableExtensions

title Gnezdo Local Development
color 0A

set "PROJECT_DIR=%USERPROFILE%\Downloads\Hakaton-main\Hakaton-main"
set "SCRIPTS_DIR=%PROJECT_DIR%\scripts"
set "START_PS1=%SCRIPTS_DIR%\start-gnezdo.ps1"
set "SERVER_PS1=%SCRIPTS_DIR%\serve-static.ps1"
set "START_URL=https://raw.githubusercontent.com/Vatnik12/Hakaton/main/scripts/start-gnezdo.ps1"
set "SERVER_URL=https://raw.githubusercontent.com/Vatnik12/Hakaton/main/scripts/serve-static.ps1"

if not exist "%SCRIPTS_DIR%" mkdir "%SCRIPTS_DIR%"

echo.
echo ============================================================
echo              GNEZDO WINDOWS BOOTSTRAP
echo ============================================================
echo Project folder: %PROJECT_DIR%
echo.
echo [BOOT] Refreshing launcher scripts from GitHub...

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -UseBasicParsing '%START_URL%' -OutFile '%START_PS1%' -TimeoutSec 45; Invoke-WebRequest -UseBasicParsing '%SERVER_URL%' -OutFile '%SERVER_PS1%' -TimeoutSec 45; Write-Host '[BOOT] Launcher scripts updated.' -ForegroundColor Green; exit 0 } catch { Write-Host ('[BOOT] Download failed: ' + $_.Exception.Message) -ForegroundColor Yellow; exit 1 }"

if errorlevel 1 (
    echo [BOOT] GitHub is unavailable. Trying cached scripts...
)

if not exist "%START_PS1%" goto fail
if not exist "%SERVER_PS1%" goto fail

echo [BOOT] Starting main launcher...
echo.
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%START_PS1%" -PreferredPath "%PROJECT_DIR%" -Port 8080
set "EXIT_CODE=%ERRORLEVEL%"

echo.
echo ============================================================
echo Launcher finished with code %EXIT_CODE%.
echo ============================================================
pause
exit /b %EXIT_CODE%

:fail
echo.
echo ERROR: launcher scripts are missing.
echo Check the internet connection and run START_GNEZDO.bat again.
pause
exit /b 1
