@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Гнездо - локальная разработка
color 0A

set "REPO_URL=https://github.com/Vatnik12/Hakaton.git"
set "ZIP_URL=https://github.com/Vatnik12/Hakaton/archive/refs/heads/main.zip"
set "PORT=8080"
set "PID_FILE=%TEMP%\gnezdo-local-server.pid"
set "PREFERRED_DIR=C:\Users\main\Downloads\Hakaton-main\Hakaton-main"
set "FALLBACK_DIR=%LOCALAPPDATA%\GnezdoDev\Hakaton"
set "WORK_DIR="
set "SYNC_MODE="

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"

echo.
echo ============================================================
echo                 ГНЕЗДО - ЛОКАЛЬНЫЙ ЗАПУСК
echo ============================================================
echo Это окно не закрывается само.
echo Здесь виден весь прогресс обновления и работы сайта.
echo.

echo [1/6] Ищу постоянную папку проекта...

if exist "%PREFERRED_DIR%\index.html" (
    set "WORK_DIR=%PREFERRED_DIR%"
    echo       Использую основную папку:
    echo       %PREFERRED_DIR%
) else if exist "%SCRIPT_DIR%\index.html" (
    set "WORK_DIR=%SCRIPT_DIR%"
    echo       Основная папка не найдена, использую папку батника:
    echo       %SCRIPT_DIR%
) else if exist "%FALLBACK_DIR%\index.html" (
    set "WORK_DIR=%FALLBACK_DIR%"
    echo       Использую резервную папку:
    echo       %FALLBACK_DIR%
) else (
    set "WORK_DIR=%PREFERRED_DIR%"
    echo       Проект будет создан в основной папке:
    echo       %PREFERRED_DIR%
)

echo.
echo [2/6] Проверяю наличие обновлений в GitHub...
where git >nul 2>nul
if errorlevel 1 goto ZIP_SYNC

set "GIT_HTTP_LOW_SPEED_LIMIT=1000"
set "GIT_HTTP_LOW_SPEED_TIME=20"

if exist "%WORK_DIR%\.git" (
    set "SYNC_MODE=git"
    echo       Git-репозиторий найден.
    echo       Получаю данные origin/main...
    git -C "%WORK_DIR%" fetch origin main --prune --progress
    if errorlevel 1 goto UPDATE_FAILED

    for /f %%H in ('git -C "%WORK_DIR%" rev-parse HEAD 2^>nul') do set "LOCAL_SHA=%%H"
    for /f %%H in ('git -C "%WORK_DIR%" rev-parse origin/main 2^>nul') do set "REMOTE_SHA=%%H"

    if /I "!LOCAL_SHA!"=="!REMOTE_SHA!" (
        echo       Обновлений нет. Локальная версия актуальна.
    ) else (
        echo       Найдена новая версия.
        echo       Локально: !LOCAL_SHA!
        echo       GitHub:   !REMOTE_SHA!
        echo       Обновляю файлы прямо в папке проекта...
        git -C "%WORK_DIR%" reset --hard origin/main
        if errorlevel 1 goto UPDATE_FAILED
        git -C "%WORK_DIR%" clean -fd -e .env
        echo       Обновление завершено.
    )
    goto CODE_READY
)

echo       Папка пока не является Git-репозиторием.
echo       Создаю временный клон и синхронизирую файлы...
set "TEMP_CLONE=%TEMP%\gnezdo-git-sync"
if exist "%TEMP_CLONE%" rmdir /s /q "%TEMP_CLONE%"
git clone --depth 1 --branch main --progress "%REPO_URL%" "%TEMP_CLONE%"
if errorlevel 1 goto CLONE_FAILED

if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
robocopy "%TEMP_CLONE%" "%WORK_DIR%" /MIR /XD ".git" /XF ".env" >nul
if errorlevel 8 goto COPY_FAILED

if exist "%WORK_DIR%\.git" rmdir /s /q "%WORK_DIR%\.git"
move "%TEMP_CLONE%\.git" "%WORK_DIR%\.git" >nul
rmdir /s /q "%TEMP_CLONE%"
set "SYNC_MODE=git"
echo       Основная папка превращена в рабочий Git-репозиторий.
goto CODE_READY

:ZIP_SYNC
echo       Git не установлен. Использую ZIP-синхронизацию.
set "SYNC_MODE=zip"
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; $zip=Join-Path $env:TEMP 'gnezdo-main.zip'; $tmp=Join-Path $env:TEMP 'gnezdo-main-extract'; if(Test-Path $zip){Remove-Item $zip -Force}; if(Test-Path $tmp){Remove-Item $tmp -Recurse -Force}; Write-Host '      Скачиваю последнюю версию...'; Invoke-WebRequest -UseBasicParsing '%ZIP_URL%' -OutFile $zip -TimeoutSec 120; Write-Host '      Распаковываю...'; Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force; $src=Join-Path $tmp 'Hakaton-main'; $dst='%WORK_DIR%'; New-Item -ItemType Directory -Force -Path $dst | Out-Null; Get-ChildItem -LiteralPath $src -Force | ForEach-Object { $target=Join-Path $dst $_.Name; if(Test-Path $target){Remove-Item $target -Recurse -Force}; Move-Item -LiteralPath $_.FullName -Destination $target }; Remove-Item $zip -Force; Remove-Item $tmp -Recurse -Force; Write-Host '      Файлы обновлены.'"
if errorlevel 1 goto UPDATE_FAILED
goto CODE_READY

:CLONE_FAILED
echo.
echo       ВНИМАНИЕ: GitHub недоступен или интернет слишком медленный.
if exist "%WORK_DIR%\index.html" (
    echo       Запускаю последнюю сохранённую версию.
    goto CODE_READY
)
goto FATAL

:COPY_FAILED
echo       ОШИБКА: не удалось скопировать обновление в папку проекта.
goto FATAL

:UPDATE_FAILED
echo.
echo       ВНИМАНИЕ: проверить или скачать обновление не удалось.
if exist "%WORK_DIR%\index.html" (
    echo       Запускаю последнюю сохранённую версию без обновления.
    goto CODE_READY
)
goto FATAL

:CODE_READY
echo.
echo [3/6] Проверяю файлы проекта...
if not exist "%WORK_DIR%\index.html" (
    echo       ОШИБКА: не найден index.html
    goto FATAL
)
if not exist "%WORK_DIR%\scripts\serve-static.ps1" (
    echo       ОШИБКА: не найден scripts\serve-static.ps1
    goto FATAL
)
echo       Файлы проекта готовы.
echo       Постоянная папка: %WORK_DIR%
echo       Режим синхронизации: %SYNC_MODE%

echo.
echo [4/6] Останавливаю предыдущий локальный сервер...
if exist "%PID_FILE%" (
    set /p OLD_PID=<"%PID_FILE%"
    if defined OLD_PID (
        echo       Завершаю процесс PID !OLD_PID!...
        taskkill /PID !OLD_PID! /T /F >nul 2>nul
    )
    del /q "%PID_FILE%" >nul 2>nul
)
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$owners=Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique; foreach($processId in $owners){Write-Host ('      Освобождаю порт %PORT%, PID '+$processId); Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue}" 2>nul

echo.
echo [5/6] Создаю удобный ярлык на рабочем столе...
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$desktop=[Environment]::GetFolderPath('Desktop'); $link=Join-Path $desktop 'Гнездо - запуск.lnk'; $ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut($link); $s.TargetPath=Join-Path '%WORK_DIR%' 'START_GNEZDO.bat'; $s.WorkingDirectory='%WORK_DIR%'; $s.Description='Обновить GitHub main и запустить Гнездо локально'; $s.Save()" >nul 2>nul
echo       Ярлык готов: Гнездо - запуск

echo.
echo [6/6] Запускаю локальный сайт...
echo       Адрес: http://localhost:%PORT%
echo       Браузер откроется автоматически.
echo       НЕ ЗАКРЫВАЙТЕ ЭТО ОКНО, пока работаете с сайтом.
echo       Для остановки нажмите Ctrl+C.
echo.

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%WORK_DIR%\scripts\serve-static.ps1" -Root "%WORK_DIR%" -Port %PORT% -PidFile "%PID_FILE%" -OpenBrowser
set "SERVER_EXIT=%ERRORLEVEL%"

echo.
echo ============================================================
if "%SERVER_EXIT%"=="0" (
    echo Локальный сервер остановлен.
) else (
    echo Сервер завершился с ошибкой. Код: %SERVER_EXIT%
)
echo ============================================================
pause
exit /b %SERVER_EXIT%

:FATAL
echo.
echo ============================================================
echo ОШИБКА ЗАПУСКА
echo Не удалось получить рабочую копию проекта.
echo Проверьте сообщения выше. Окно останется открытым.
echo ============================================================
pause
exit /b 1
