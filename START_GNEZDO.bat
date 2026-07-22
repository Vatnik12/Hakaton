@echo off
setlocal EnableExtensions

title Gnezdo - Offline Update and Start
color 0A

set "PROJECT_DIR=%USERPROFILE%\Desktop\Hakaton"
set "DOWNLOADS_DIR=%USERPROFILE%\Downloads"
set "BUNDLED_PS1=%~dp0scripts\start-gnezdo.ps1"
set "INSTALLED_PS1=%PROJECT_DIR%\scripts\start-gnezdo.ps1"
set "TEMP_PS1=%TEMP%\gnezdo-offline-%RANDOM%-%RANDOM%.ps1"

echo.
echo ============================================================
echo              GNEZDO - OFFLINE UPDATE AND START
echo ============================================================
echo Archives: %DOWNLOADS_DIR%\Hakaton-main*.zip
echo Project:  %PROJECT_DIR%
echo.

if exist "%BUNDLED_PS1%" (
    set "SOURCE_PS1=%BUNDLED_PS1%"
) else if exist "%INSTALLED_PS1%" (
    set "SOURCE_PS1=%INSTALLED_PS1%"
) else (
    goto fail
)

copy /Y "%SOURCE_PS1%" "%TEMP_PS1%" >nul
if errorlevel 1 goto fail

echo Starting the offline archive updater...
start "Gnezdo - Offline Update and Start" powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -NoExit -File "%TEMP_PS1%" -ProjectPath "%PROJECT_DIR%" -DownloadsPath "%DOWNLOADS_DIR%" -Port 8080
exit /b 0

:fail
echo.
echo ERROR: scripts\start-gnezdo.ps1 was not found.
echo Put this BAT inside the Hakaton project and run it again.
pause
exit /b 1
