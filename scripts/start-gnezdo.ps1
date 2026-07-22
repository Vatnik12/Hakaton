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
        throw "Git failed with code ${code}: git $($Arguments -join ' ')"
    }

    if ($AllowFailure) {
        return $code
    }
}

function Test-CommandExists {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Ensure-GitOrigin {
    param([string]$Path)

    $currentOrigin = & git -C $Path remote get-url origin 2>$null
    if ($LASTEXITCODE -eq 0) {
        Invoke-Git @('-C', $Path, 'remote', 'set-url', 'origin', $repoUrl)
        Write-Info 'Existing origin remote was refreshed.'
    } else {
        Invoke-Git @('-C', $Path, 'remote', 'add', 'origin', $repoUrl)
        Write-Info 'Origin remote was added.'
    }
}

function Sync-WithGit {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }

    if (-not (Test-Path (Join-Path $Path '.git'))) {
        Write-Info 'Folder is not a Git repository yet.'
        Write-Info 'Initializing Git in this exact folder...'
        Invoke-Git @('-C', $Path, 'init')
    } else {
        Write-Info 'Git metadata found in the project folder.'
    }

    Ensure-GitOrigin -Path $Path

    Write-Info 'Downloading the latest main branch metadata...'
    Invoke-Git @('-C', $Path, 'fetch', '--depth', '1', '--prune', '--progress', 'origin', 'main')

    $remoteSha = (& git -C $Path rev-parse FETCH_HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($remoteSha)) {
        throw 'Could not read the downloaded GitHub commit.'
    }

    $localValue = & git -C $Path rev-parse --verify HEAD 2>$null
    $hasLocalCommit = $LASTEXITCODE -eq 0
    $localSha = if ($hasLocalCommit) { $localValue.Trim() } else { '' }

    if (-not $hasLocalCommit) {
        Write-Info 'The partial repository has no local commit yet.'
        Write-Host '      Installing the downloaded main branch...' -ForegroundColor Yellow
        Invoke-Git @('-C', $Path, 'reset', '--hard', 'FETCH_HEAD')
        Invoke-Git @('-C', $Path, 'branch', '-M', 'main')
        Invoke-Git @('-C', $Path, 'clean', '-fd', '-e', '.env')
        Write-Host '      Project folder is now fully connected and updated.' -ForegroundColor Green
        return
    }

    Write-Info "Local version:  $($localSha.Substring(0, 8))"
    Write-Info "GitHub version: $($remoteSha.Substring(0, 8))"

    if ($localSha -eq $remoteSha) {
        Write-Host '      No updates found. Project is current.' -ForegroundColor Green
        return
    }

    Write-Host '      Update found. Replacing project files...' -ForegroundColor Yellow
    Invoke-Git @('-C', $Path, 'reset', '--hard', 'FETCH_HEAD')
    Invoke-Git @('-C', $Path, 'branch', '-M', 'main')
    Invoke-Git @('-C', $Path, 'clean', '-fd', '-e', '.env')
    Write-Host '      Update installed successfully.' -ForegroundColor Green
}

function Sync-WithZip {
    param([string]$Path)

    $zipPath = Join-Path $env:TEMP 'gnezdo-main.zip'
    $extractPath = Join-Path $env:TEMP 'gnezdo-main-extract'

    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue

    Write-Info 'Downloading the latest ZIP from GitHub...'

    if (Test-CommandExists 'curl.exe') {
        & curl.exe -L --fail --retry 2 --connect-timeout 15 --progress-bar $zipUrl -o $zipPath
        if ($LASTEXITCODE -ne 0) {
            throw "curl.exe failed with code $LASTEXITCODE"
        }
    } else {
        Invoke-WebRequest -UseBasicParsing -Uri $zipUrl -OutFile $zipPath -TimeoutSec 120
    }

    Write-Info 'Extracting update...'
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

    $source = Join-Path $extractPath 'Hakaton-main'
    if (-not (Test-Path (Join-Path $source 'index.html'))) {
        throw 'Downloaded archive does not contain index.html.'
    }

    New-Item -ItemType Directory -Force -Path $Path | Out-Null

    Write-Info 'Synchronizing files into the permanent project folder...'
    & robocopy.exe $source $Path /MIR /XD '.git' /XF '.env' /R:2 /W:1 /NFL /NDL /NJH /NJS /NP
    $robocopyCode = $LASTEXITCODE
    if ($robocopyCode -ge 8) {
        throw "Robocopy failed with code $robocopyCode"
    }

    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host '      Latest ZIP version installed.' -ForegroundColor Green
}

function Stop-PreviousServer {
    param([int]$ServerPort)

    if (Test-Path $pidFile) {
        $oldPid = Get-Content $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($oldPid -match '^\d+$') {
            Write-Info "Stopping previous server PID $oldPid..."
            Stop-Process -Id ([int]$oldPid) -Force -ErrorAction SilentlyContinue
        }
        Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    }

    $listeners = Get-NetTCPConnection -LocalPort $ServerPort -State Listen -ErrorAction SilentlyContinue
    foreach ($listener in $listeners) {
        if ($listener.OwningProcess -and $listener.OwningProcess -ne $PID) {
            Write-Info "Freeing port $ServerPort from PID $($listener.OwningProcess)..."
            Stop-Process -Id $listener.OwningProcess -Force -ErrorAction SilentlyContinue
        }
    }
}

function Test-DockerReady {
    if (-not (Test-CommandExists 'docker.exe')) {
        return $false
    }

    & docker info --format '{{.ServerVersion}}' *> $null
    return $LASTEXITCODE -eq 0
}

function Start-DockerStack {
    param([string]$Path)

    $composePath = Join-Path $Path 'docker-compose.yml'
    if (-not (Test-Path $composePath)) {
        throw "Missing file: $composePath"
    }

    Write-Info 'Docker Desktop is running. Starting the complete application...'
    Write-Info 'This includes PostgreSQL, the Java API and the website.'

    Push-Location $Path
    try {
        & docker compose up -d --build --remove-orphans
        if ($LASTEXITCODE -ne 0) {
            throw "docker compose failed with code $LASTEXITCODE"
        }
    } finally {
        Pop-Location
    }

    Write-Info 'Waiting for the website and API to become ready...'
    $healthUrl = 'http://localhost/api/v1/health'
    $ready = $false

    for ($attempt = 1; $attempt -le 60; $attempt++) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $healthUrl -TimeoutSec 3
            if ($response.StatusCode -eq 200) {
                $ready = $true
                break
            }
        } catch {}

        Start-Sleep -Seconds 2
    }

    if (-not $ready) {
        throw 'The containers started, but the API did not become ready within two minutes.'
    }

    Write-Host '      Complete Gnezdo stack is ready.' -ForegroundColor Green
    Write-Host '      Website: http://localhost' -ForegroundColor Green
    Write-Host '      API:     http://localhost/api/v1/health' -ForegroundColor Green
    Start-Process "http://localhost/?dev=$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())"
}

function Create-DesktopShortcut {
    param([string]$Path)

    try {
        $desktop = [Environment]::GetFolderPath('Desktop')
        $shortcutPath = Join-Path $desktop 'Gnezdo - Launch.lnk'
        $batPath = Join-Path $Path 'START_GNEZDO.bat'
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $batPath
        $shortcut.WorkingDirectory = $Path
        $shortcut.Description = 'Update Gnezdo from GitHub and run it locally'
        $shortcut.Save()
        Write-Info 'Desktop shortcut created: Gnezdo - Launch'
    } catch {
        Write-Info "Could not create desktop shortcut: $($_.Exception.Message)"
    }
}

Clear-Host
Write-Host '============================================================' -ForegroundColor DarkGreen
Write-Host '             GNEZDO LOCAL DEVELOPMENT' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor DarkGreen
Write-Host 'This console will stay open and show all progress.' -ForegroundColor Gray

Write-Step 1 'Locating the permanent project folder'

if ((Test-Path (Join-Path $PreferredPath 'index.html')) -or (Test-Path $PreferredPath)) {
    $workDir = $PreferredPath
} elseif (Test-Path (Join-Path $scriptRoot 'index.html')) {
    $workDir = $scriptRoot
} else {
    $workDir = $PreferredPath
}

Write-Info "Permanent folder: $workDir"
New-Item -ItemType Directory -Force -Path $workDir | Out-Null

Write-Step 2 'Checking GitHub for updates'

try {
    if (Test-CommandExists 'git.exe') {
        try {
            Sync-WithGit -Path $workDir
        } catch {
            Write-Host "      Git update failed: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host '      Switching automatically to the GitHub ZIP download...' -ForegroundColor Yellow
            Sync-WithZip -Path $workDir
        }
    } else {
        Write-Info 'Git is not installed. Using the ZIP download.'
        Sync-WithZip -Path $workDir
    }
} catch {
    Write-Host "      Update failed: $($_.Exception.Message)" -ForegroundColor Yellow

    if (Test-Path (Join-Path $workDir 'index.html')) {
        Write-Host '      GitHub is unavailable. Starting the last saved version.' -ForegroundColor Yellow
    } else {
        throw
    }
}

Write-Step 3 'Checking project files'
$indexPath = Join-Path $workDir 'index.html'
$serverPath = Join-Path $workDir 'scripts\serve-static.ps1'

if (-not (Test-Path $indexPath)) {
    throw "Missing file: $indexPath"
}

if (-not (Test-Path $serverPath)) {
    throw "Missing file: $serverPath"
}

Write-Info 'Core project files are ready.'
Write-Info "Serving files from: $workDir"

Write-Step 4 'Stopping the previous local server'
Stop-PreviousServer -ServerPort $Port
Write-Info "Port $Port is ready."

Write-Step 5 'Creating a shortcut for future launches'
Create-DesktopShortcut -Path $workDir

Write-Step 6 'Starting the ready website'

if (Test-DockerReady) {
    try {
        Start-DockerStack -Path $workDir
        Write-Host ''
        Write-Host 'The containers keep running in the background.' -ForegroundColor Gray
        Write-Host 'You can close this window.' -ForegroundColor Gray
        exit 0
    } catch {
        Write-Host "      Full Docker launch failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host '      Falling back to the frontend-only local server.' -ForegroundColor Yellow
    }
} else {
    Write-Host '      Docker Desktop was not found or is not running.' -ForegroundColor Yellow
    Write-Host '      Starting the frontend-only fallback.' -ForegroundColor Yellow
}

Write-Host "      URL: http://localhost:$Port" -ForegroundColor Green
Write-Host '      The browser will open automatically.' -ForegroundColor Green
Write-Host '      Keep this window open while using the site.' -ForegroundColor Yellow
Write-Host '      Press Ctrl+C to stop the local server.' -ForegroundColor Yellow
Write-Host ''

& $serverPath -Root $workDir -Port $Port -PidFile $pidFile -OpenBrowser
exit $LASTEXITCODE
