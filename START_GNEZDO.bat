@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Гнездо - локальная разработка
color 0A

set "REPO_URL=https://github.com/Vatnik12/Hakaton.git"
set "ZIP_URL=https://github.com/Vatnik12/Hakaton/archive/refs/heads/main.zip"
set "PORT=8080"
set "PID_FILE=%TEMP%\gnezdo-local-server.pid"
set "CACHE_DIR=%LOCALAPPDATA%\GnezdoDev\Hakaton"

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"
set "WORK_DIR="

echo.
echo ============================================================
echo                 ГНЕЗДО - ЛОКАЛЬНЫЙ ЗАПУСК
echo ============================================================
echo Это окно теперь не закрывается само.
echo Здесь будет виден весь прогресс и журнал запросов сайта.
echo.

echo [1/5] Ищу рабочую копию проекта...
if exist "%SCRIPT_DIR%\index.html" (
    set "WORK_DIR=%SCRIPT_DIR%"
    echo       Найдена копия рядом с батником:
    echo       %SCRIPT_DIR%
) else if exist "%CACHE_DIR%\index.html" (
    set "WORK_DIR=%CACHE_DIR%"
    echo       Найдена сохранённая копия:
    echo       %CACHE_DIR%
) else (
    echo       Сохранённая копия пока не найдена.
)

echo.
echo [2/5] Проверяю обновления на GitHub...
where git >nul 2>nul
if errorlevel 1 goto NO_GIT

set "GIT_HTTP_LOW_SPEED_LIMIT=1000"
set "GIT_HTTP_LOW_SPEED_TIME=15"

if exist "%SCRIPT_DIR%\.git" (
    set "WORK_DIR=%SCRIPT_DIR%"
    echo       Обновляю Git-репозиторий рядом с батником...
    git -C "%WORK_DIR%" fetch origin main --prune --progress
    if errorlevel 1 goto UPDATE_FAILED
    git -C "%WORK_DIR%" reset --hard origin/main
    if errorlevel 1 goto UPDATE_FAILED
    echo       Проект обновлён до последнего main.
    goto CODE_READY
)

if exist "%CACHE_DIR%\.git" (
    set "WORK_DIR=%CACHE_DIR%"
    echo       Обновляю сохранённый Git-репозиторий...
    git -C "%WORK_DIR%" fetch origin main --prune --progress
    if errorlevel 1 goto UPDATE_FAILED
    git -C "%WORK_DIR%" reset --hard origin/main
    if errorlevel 1 goto UPDATE_FAILED
    echo       Проект обновлён до последнего main.
    goto CODE_READY
)

echo       Клонирую проект в постоянную папку:
echo       %CACHE_DIR%
for %%I in ("%CACHE_DIR%\..") do if not exist "%%~fI" mkdir "%%~fI"
if exist "%CACHE_DIR%" rmdir /s /q "%CACHE_DIR%"
git clone --depth 1 --branch main --progress "%REPO_URL%" "%CACHE_DIR%"
if errorlevel 1 goto CLONE_FAILED
set "WORK_DIR=%CACHE_DIR%"
echo       Последняя версия скачана.
goto CODE_READY

:NO_GIT
echo       Git не установлен.
if defined WORK_DIR (
    echo       Запускаю найденную локальную копию без обновления.
    goto CODE_READY
)
echo       Пытаюсь скачать ZIP последней версии через PowerShell...
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='Continue'; $zip=Join-Path $env:TEMP 'gnezdo-main.zip'; $tmp=Join-Path $env:TEMP 'gnezdo-main-extract'; if(Test-Path $zip){Remove-Item $zip -Force}; if(Test-Path $tmp){Remove-Item $tmp -Recurse -Force}; Invoke-WebRequest -UseBasicParsing '%ZIP_URL%' -OutFile $zip -TimeoutSec 90; Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force; $src=Join-Path $tmp 'Hakaton-main'; $dst='%CACHE_DIR%'; if(Test-Path $dst){Remove-Item $dst -Recurse -Force}; New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null; Move-Item -LiteralPath $src -Destination $dst; Remove-Item $zip -Force; Remove-Item $tmp -Recurse -Force"
if errorlevel 1 goto FATAL
set "WORK_DIR=%CACHE_DIR%"
goto CODE_READY

:CLONE_FAILED
echo.
echo       ВНИМАНИЕ: GitHub сейчас недоступен или интернет слишком медленный.
if defined WORK_DIR (
    echo       Запускаю уже имеющуюся копию: %WORK_DIR%
    goto CODE_READY
)
goto FATAL

:UPDATE_FAILED
echo.
echo       ВНИМАНИЕ: обновление не удалось.
echo       Возможно, плохой интернет. Текущая копия не удалена.
if defined WORK_DIR goto CODE_READY
goto FATAL

:CODE_READY
echo.
echo [3/5] Проверяю файлы проекта...
if not defined WORK_DIR goto FATAL
if not exist "%WORK_DIR%\index.html" (
    echo       ОШИБКА: не найден index.html
    goto FATAL
)
if not exist "%WORK_DIR%\scripts\serve-static.ps1" (
    echo       ОШИБКА: не найден scripts\serve-static.ps1
    echo       Скачайте свежую версию репозитория один раз.
    goto FATAL
)
echo       Файлы найдены.
echo       Рабочая папка: %WORK_DIR%

echo.
echo [4/5] Останавливаю предыдущий локальный сервер...
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
echo [5/5] Запускаю локальный сайт...
echo       Адрес: http://localhost:%PORT%
echo       После запуска браузер откроется автоматически.
echo       НЕ ЗАКРЫВАЙТЕ ЭТО ОКНО, пока работаете с сайтом.
echo       Для остановки нажмите Ctrl+C.
echo.

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$desktop=[Environment]::GetFolderPath('Desktop'); $link=Join-Path $desktop 'Гнездо - запуск.lnk'; $ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut($link); $s.TargetPath=Join-Path '%WORK_DIR%' 'START_GNEZDO.bat'; $s.WorkingDirectory='%WORK_DIR%'; $s.Description='Обновить и запустить Гнездо локально'; $s.Save()" >nul 2>nul

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
echo Нажмите любую клавишу, чтобы закрыть окно.
pause >nul
exit /b %SERVER_EXIT%

:FATAL
echo.
echo ============================================================
echo ОШИБКА ЗАПУСКА
 echo Не удалось получить рабочую копию проекта.
echo Проверьте сообщения выше. Это окно останется открытым.
echo ============================================================
pause
exit /b 1
