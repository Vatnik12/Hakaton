@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Гнездо - обновление и локальный запуск

set "REPO_URL=https://github.com/Vatnik12/Hakaton.git"
set "ZIP_URL=https://github.com/Vatnik12/Hakaton/archive/refs/heads/main.zip"
set "PORT=8080"
set "PID_FILE=%TEMP%\gnezdo-local-server.pid"
set "DEFAULT_DIR=%LOCALAPPDATA%\GnezdoDev\Hakaton"

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"

if exist "%SCRIPT_DIR%\.git" (
    set "WORK_DIR=%SCRIPT_DIR%"
) else (
    set "WORK_DIR=%DEFAULT_DIR%"
)

echo.
echo ============================================================
echo                 ГНЕЗДО - БЫСТРЫЙ ЗАПУСК
echo ============================================================
echo.
echo [1/4] Получаю последнюю версию проекта...

where git >nul 2>nul
if errorlevel 1 goto ZIP_MODE

if exist "%WORK_DIR%\.git" (
    git -C "%WORK_DIR%" fetch origin main --prune
    if errorlevel 1 goto OFFLINE_MODE
    git -C "%WORK_DIR%" reset --hard origin/main
    if errorlevel 1 goto FAIL
) else (
    if exist "%WORK_DIR%" rmdir /s /q "%WORK_DIR%"
    for %%I in ("%WORK_DIR%\..") do if not exist "%%~fI" mkdir "%%~fI"
    git clone --depth 1 --branch main "%REPO_URL%" "%WORK_DIR%"
    if errorlevel 1 goto FAIL
)
goto HAVE_CODE

:ZIP_MODE
echo Git не найден. Использую загрузку ZIP через PowerShell...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $zip=Join-Path $env:TEMP 'gnezdo-main.zip'; $tmp=Join-Path $env:TEMP 'gnezdo-main-extract'; if(Test-Path $zip){Remove-Item $zip -Force}; if(Test-Path $tmp){Remove-Item $tmp -Recurse -Force}; Invoke-WebRequest -UseBasicParsing '%ZIP_URL%' -OutFile $zip; Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force; $src=Join-Path $tmp 'Hakaton-main'; $dst='%WORK_DIR%'; if(Test-Path $dst){Remove-Item $dst -Recurse -Force}; New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null; Move-Item -LiteralPath $src -Destination $dst; Remove-Item $zip -Force; Remove-Item $tmp -Recurse -Force"
if errorlevel 1 goto OFFLINE_MODE
goto HAVE_CODE

:OFFLINE_MODE
if exist "%WORK_DIR%\index.html" (
    echo Интернет недоступен. Запускаю последнюю сохранённую копию.
    goto HAVE_CODE
)
echo Локальной копии пока нет, а GitHub недоступен.
goto FAIL

:HAVE_CODE
if not exist "%WORK_DIR%\index.html" goto FAIL
if not exist "%WORK_DIR%\scripts\serve-static.ps1" goto FAIL

echo [2/4] Останавливаю предыдущий локальный сервер...
if exist "%PID_FILE%" (
    set /p OLD_PID=<"%PID_FILE%"
    if defined OLD_PID taskkill /PID !OLD_PID! /T /F >nul 2>nul
    del /q "%PID_FILE%" >nul 2>nul
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$owners=Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique; foreach($owner in $owners){Stop-Process -Id $owner -Force -ErrorAction SilentlyContinue}" >nul 2>nul

echo [3/4] Запускаю сайт на http://localhost:%PORT% ...
start "Гнездо - локальный сервер" powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%WORK_DIR%\scripts\serve-static.ps1" -Root "%WORK_DIR%" -Port %PORT% -PidFile "%PID_FILE%"

for /L %%N in (1,1,20) do (
    powershell -NoProfile -Command "try{$r=Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:%PORT%/' -TimeoutSec 1; if($r.StatusCode -eq 200){exit 0}; exit 1}catch{exit 1}" >nul 2>nul
    if not errorlevel 1 goto READY
    timeout /t 1 /nobreak >nul
)
goto SERVER_FAIL

:READY
echo [4/4] Сайт готов. Открываю браузер...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$desktop=[Environment]::GetFolderPath('Desktop'); $link=Join-Path $desktop 'Гнездо - запуск.lnk'; $ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut($link); $s.TargetPath=Join-Path '%WORK_DIR%' 'START_GNEZDO.bat'; $s.WorkingDirectory='%WORK_DIR%'; $s.Description='Обновить и запустить Гнездо локально'; $s.Save()" >nul 2>nul
start "" "http://localhost:%PORT%/?dev=%RANDOM%"
echo.
echo Готово: http://localhost:%PORT%
echo Рабочая папка: %WORK_DIR%
echo На рабочем столе создан ярлык "Гнездо - запуск".
echo При следующем запуске проект снова обновится с GitHub.
echo.
timeout /t 4 /nobreak >nul
exit /b 0

:SERVER_FAIL
echo.
echo Сервер не запустился за 20 секунд.
echo Проверьте окно "Гнездо - локальный сервер" с текстом ошибки.
pause
exit /b 1

:FAIL
echo.
echo Не удалось обновить или запустить проект.
echo Проверьте интернет и повторите запуск файла START_GNEZDO.bat.
pause
exit /b 1
