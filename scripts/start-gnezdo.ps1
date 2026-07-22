param(
    [string]$PreferredPath = "$env:USERPROFILE\Downloads\Hakaton-main\Hakaton-main",
    [int]$Port = 8080
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'Continue'

$repoUrl = 'https://github.com/Vatnik12/Hakaton.git'
$zipUrl = 'https://github.com/Vatnik12/Hakaton/archive/refs/heads/main.zip'
$pidFile = Join-Path $env:TEMP 'gnezdo-local-server.pid'
$scriptRoot = Split-Path -Parent $PSScriptRoot
$workDir = $PreferredPath

function Write-Step {
    param([int]$Number, [string]$Text)
    Write-Host ''
    Write-Host "[$Number/6] $Text" -ForegroundColor Cyan
}

function Write-Info {
    param([string]$Text)
    Write-Host "      $Text" -ForegroundColor Gray
}

function Invoke-Git {
    param([string[]]$Arguments, [switch]$AllowFailure)

    & git @Arguments
    $code = $LASTEXITCODE

    if ($code -ne 0 -and -not $AllowFailure) {
        throw "Git завершился с кодом $code: git $($Arguments -join ' ')"
    }

    return $code
}

function Test-CommandExists {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Sync-WithGit {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }

    if (-not (Test-Path (Join-Path $Path '.git'))) {
        Write-Info 'Папка пока не является Git-репозиторием.'
        Write-Info 'Подключаю её к GitHub без создания второй копии...'

        Invoke-Git @('-C', $Path, 'init') | Out-Null
        Invoke-Git @('-C', $Path, 'remote', 'remove', 'origin') -AllowFailure | Out-Null
        Invoke-Git @('-C', $Path, 'remote', 'add', 'origin', $repoUrl) | Out-Null
        Invoke-Git @('-C', $Path, 'fetch', '--depth', '1', '--progress', 'origin', 'main')
        Invoke-Git @('-C', $Path, 'reset', '--hard', 'FETCH_HEAD')
        Invoke-Git @('-C', $Path, 'branch', '-M', 'main')
        Invoke-Git @('-C', $Path, 'clean', '-fd', '-e', '.env')

        Write-Info 'Папка подключена к GitHub и полностью обновлена.'
        return
    }

    Write-Info 'Git-репозиторий найден. Проверяю origin/main...'
    Invoke-Git @('-C', $Path, 'remote', 'set-url', 'origin', $repoUrl)
    Invoke-Git @('-C', $Path, 'fetch', '--prune', '--progress', 'origin', 'main')

    $localSha = (& git -C $Path rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Не удалось определить локальный commit.' }

    $remoteSha = (& git -C $Path rev-parse origin/main).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Не удалось определить origin/main.' }

    Write-Info "Локальная версия: $($localSha.Substring(0, 8))"
    Write-Info "Версия GitHub:   $($remoteSha.Substring(0, 8))"

    if ($localSha -eq $remoteSha) {
        Write-Host '      Обновлений нет. Проект уже актуален.' -ForegroundColor Green
        return
    }

    Write-Host '      Найдена новая версия. Обновляю файлы проекта...' -ForegroundColor Yellow
    Invoke-Git @('-C', $Path, 'reset', '--hard', 'origin/main')
    Invoke-Git @('-C', $Path, 'clean', '-fd', '-e', '.env')
    Write-Host '      Обновление успешно установлено.' -ForegroundColor Green
}

function Sync-WithZip {
    param([string]$Path)

    $zipPath = Join-Path $env:TEMP 'gnezdo-main.zip'
    $extractPath = Join-Path $env:TEMP 'gnezdo-main-extract'

    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue

    Write-Info 'Git не найден. Скачиваю свежий ZIP с GitHub...'

    if (Test-CommandExists 'curl.exe') {
        & curl.exe -L --fail --retry 2 --connect-timeout 15 --progress-bar $zipUrl -o $zipPath
        if ($LASTEXITCODE -ne 0) {
            throw "curl.exe завершился с кодом $LASTEXITCODE"
        }
    } else {
        Invoke-WebRequest -UseBasicParsing -Uri $zipUrl -OutFile $zipPath -TimeoutSec 120
    }

    Write-Info 'Распаковываю обновление...'
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

    $source = Join-Path $extractPath 'Hakaton-main'
    if (-not (Test-Path (Join-Path $source 'index.html'))) {
        throw 'В скачанном архиве не найден index.html.'
    }

    New-Item -ItemType Directory -Force -Path $Path | Out-Null

    Write-Info 'Синхронизирую файлы с постоянной папкой проекта...'
    & robocopy.exe $source $Path /MIR /XD '.git' /XF '.env' /R:2 /W:1 /NFL /NDL /NJH /NJS /NP
    $robocopyCode = $LASTEXITCODE
    if ($robocopyCode -ge 8) {
        throw "Robocopy завершился с кодом $robocopyCode"
    }

    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host '      Последняя ZIP-версия установлена.' -ForegroundColor Green
}

function Stop-PreviousServer {
    param([int]$ServerPort)

    if (Test-Path $pidFile) {
        $oldPid = Get-Content $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($oldPid -match '^\d+$') {
            Write-Info "Останавливаю предыдущий сервер PID $oldPid..."
            Stop-Process -Id ([int]$oldPid) -Force -ErrorAction SilentlyContinue
        }
        Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    }

    $listeners = Get-NetTCPConnection -LocalPort $ServerPort -State Listen -ErrorAction SilentlyContinue
    foreach ($listener in $listeners) {
        if ($listener.OwningProcess -and $listener.OwningProcess -ne $PID) {
            Write-Info "Освобождаю порт $ServerPort, PID $($listener.OwningProcess)..."
            Stop-Process -Id $listener.OwningProcess -Force -ErrorAction SilentlyContinue
        }
    }
}

function Create-DesktopShortcut {
    param([string]$Path)

    try {
        $desktop = [Environment]::GetFolderPath('Desktop')
        $shortcutPath = Join-Path $desktop 'Гнездо - запуск.lnk'
        $batPath = Join-Path $Path 'START_GNEZDO.bat'
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $batPath
        $shortcut.WorkingDirectory = $Path
        $shortcut.Description = 'Обновить проект с GitHub и запустить Гнездо локально'
        $shortcut.Save()
        Write-Info 'Ярлык «Гнездо - запуск» создан на рабочем столе.'
    } catch {
        Write-Info "Не удалось создать ярлык: $($_.Exception.Message)"
    }
}

Clear-Host
Write-Host '============================================================' -ForegroundColor DarkGreen
Write-Host '             ГНЕЗДО - ЛОКАЛЬНАЯ РАЗРАБОТКА' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor DarkGreen
Write-Host 'Консоль останется открытой и покажет весь прогресс.' -ForegroundColor Gray

Write-Step 1 'Ищу постоянную папку проекта'

if ((Test-Path (Join-Path $PreferredPath 'index.html')) -or (Test-Path $PreferredPath)) {
    $workDir = $PreferredPath
} elseif (Test-Path (Join-Path $scriptRoot 'index.html')) {
    $workDir = $scriptRoot
} else {
    $workDir = $PreferredPath
}

Write-Info "Постоянная папка: $workDir"
New-Item -ItemType Directory -Force -Path $workDir | Out-Null

Write-Step 2 'Проверяю обновления в GitHub'

try {
    if (Test-CommandExists 'git.exe') {
        Sync-WithGit -Path $workDir
    } else {
        Sync-WithZip -Path $workDir
    }
} catch {
    Write-Host "      Обновление не удалось: $($_.Exception.Message)" -ForegroundColor Yellow

    if (Test-Path (Join-Path $workDir 'index.html')) {
        Write-Host '      Интернет недоступен. Запускаю последнюю сохранённую версию.' -ForegroundColor Yellow
    } else {
        throw
    }
}

Write-Step 3 'Проверяю файлы проекта'
$indexPath = Join-Path $workDir 'index.html'
$serverPath = Join-Path $workDir 'scripts\serve-static.ps1'

if (-not (Test-Path $indexPath)) {
    throw "Не найден файл $indexPath"
}

if (-not (Test-Path $serverPath)) {
    throw "Не найден файл $serverPath"
}

Write-Info 'Основные файлы найдены.'
Write-Info "Сайт будет запущен из: $workDir"

Write-Step 4 'Останавливаю предыдущий локальный сервер'
Stop-PreviousServer -ServerPort $Port
Write-Info "Порт $Port готов."

Write-Step 5 'Создаю ярлык для следующих запусков'
Create-DesktopShortcut -Path $workDir

Write-Step 6 'Запускаю локальный сайт'
Write-Host "      Адрес: http://localhost:$Port" -ForegroundColor Green
Write-Host '      Браузер откроется автоматически.' -ForegroundColor Green
Write-Host '      Не закрывайте это окно, пока работаете с сайтом.' -ForegroundColor Yellow
Write-Host '      Для остановки нажмите Ctrl+C.' -ForegroundColor Yellow
Write-Host ''

& $serverPath -Root $workDir -Port $Port -PidFile $pidFile -OpenBrowser
exit $LASTEXITCODE
