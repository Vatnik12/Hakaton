@echo off
setlocal
set "PROJECT_DIR=%USERPROFILE%\Downloads\Hakaton-main\Hakaton-main"
set "START_PS1=%PROJECT_DIR%\scripts\start-gnezdo.ps1"
set "REMOTE_PS1=https://raw.githubusercontent.com/Vatnik12/Hakaton/main/scripts/start-gnezdo.ps1"

if not exist "%PROJECT_DIR%\scripts" mkdir "%PROJECT_DIR%\scripts"

if not exist "%START_PS1%" (
  echo Downloading launcher script...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest '%REMOTE_PS1%' -OutFile '%START_PS1%'"
  if errorlevel 1 goto fail
)

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%START_PS1%" -PreferredPath "%PROJECT_DIR%" -Port 8080
set "EXIT_CODE=%ERRORLEVEL%"

echo.
echo Launcher finished with code %EXIT_CODE%.
pause
exit /b %EXIT_CODE%

:fail
echo.
echo Failed to download scripts\start-gnezdo.ps1.
echo Check your internet connection and run this file again.
pause
exit /b 1
