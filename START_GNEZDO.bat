@echo off
setlocal EnableExtensions

title Gnezdo - Update and Start
color 0A

rem Use the folder containing this BAT when it is inside the project.
for %%I in ("%~dp0.") do set "PROJECT_DIR=%%~fI"

rem If somebody copied only the BAT to another place, keep the real project
rem in a predictable per-user folder instead of mirroring files to Desktop.
if not exist "%PROJECT_DIR%\index.html" if not exist "%PROJECT_DIR%\.git" set "PROJECT_DIR=%LOCALAPPDATA%\Gnezdo"

set "BOOTSTRAP_URL=https://raw.githubusercontent.com/Vatnik12/Hakaton/main/scripts/start-gnezdo.ps1"
set "BOOTSTRAP_PS1=%TEMP%\gnezdo-start-latest.ps1"
set "CACHED_PS1=%PROJECT_DIR%\scripts\start-gnezdo.ps1"

echo.
echo ============================================================
echo                 GNEZDO - ONE CLICK START
echo ============================================================
echo Project folder: %PROJECT_DIR%
echo.
echo [1/2] Downloading the latest launcher from GitHub...

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing '%BOOTSTRAP_URL%' -OutFile '%BOOTSTRAP_PS1%' -TimeoutSec 45"

if errorlevel 1 (
    echo [WARN] GitHub is temporarily unavailable. Using the cached launcher.
    if not exist "%CACHED_PS1%" goto fail
    set "BOOTSTRAP_PS1=%CACHED_PS1%"
) else (
    echo [OK] Latest launcher downloaded.
)

echo [2/2] Opening the updater and starting Gnezdo...

rem Start the real work from a separate process. The repository updater may
rem replace this BAT while it is running, so the bootstrap process exits now.
start "Gnezdo - Update and Start" powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -NoExit -File "%BOOTSTRAP_PS1%" -PreferredPath "%PROJECT_DIR%" -Port 8080
exit /b 0

:fail
echo.
echo ERROR: The latest launcher could not be downloaded and no cached copy exists.
echo Check the internet connection and run START_GNEZDO.bat again.
pause
exit /b 1
