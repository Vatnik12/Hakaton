param(
    [string]$ProjectPath = "$env:USERPROFILE\Desktop\Hakaton",
    [string]$DownloadsPath = "$env:USERPROFILE\Downloads",
    [int]$Port = 8080
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'Continue'

$pidFile = Join-Path $env:TEMP 'gnezdo-local-server.pid'
$stateDirectory = Join-Path $env:LOCALAPPDATA 'Gnezdo'
$stateFile = Join-Path $stateDirectory 'last-archive.sha256'
$workDir = $ProjectPath

function Write-Step {
    param([int]$Number, [string]$Text)
    Write-Host ''
    Write-Host "[$Number/7] $Text" -ForegroundColor Cyan
}

function Write-Info {
    param([string]$Text)
    Write-Host "      $Text" -ForegroundColor Gray
}

function Get-LatestHakatonArchive {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Downloads folder does not exist: $Path"
    }

    $ranked = foreach ($file in Get-ChildItem -LiteralPath $Path -File -ErrorAction Stop) {
        if ($file.Name -match '^Hakaton-main(?: \((\d+)\))?\.zip$') {
            $sequence = if ($Matches[1]) { [int]$Matches[1] } else { 0 }
            [PSCustomObject]@{
                File = $file
                Sequence = $sequence
            }
        }
    }

    $latest = $ranked |
        Sort-Object -Property `
            @{ Expression = { $_.File.LastWriteTimeUtc }; Descending = $true },
            @{ Expression = { $_.Sequence }; Descending = $true } |
        Select-Object -First 1

    if ($null -eq $latest) {
        return $null
    }

    return $latest.File
}

function Wait-ArchiveReady {
    param([System.IO.FileInfo]$Archive)

    Write-Info 'Waiting until the browser finishes writing the archive...'
    $previousLength = -1

    for ($attempt = 1; $attempt -le 30; $attempt++) {
        $current = Get-Item -LiteralPath $Archive.FullName -ErrorAction Stop
        $stream = $null

        try {
            $stream = [System.IO.File]::Open(
                $current.FullName,
                [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::Read
            )

            if ($current.Length -gt 0 -and $current.Length -eq $previousLength) {
                return (Get-Item -LiteralPath $current.FullName)
            }
        } catch {
            # The browser may still have an exclusive lock on the ZIP.
        } finally {
            if ($null -ne $stream) {
                $stream.Dispose()
            }
        }

        $previousLength = $current.Length
        Start-Sleep -Seconds 1
    }

    throw "Archive is still being downloaded or locked: $($Archive.FullName)"
}

function Install-HakatonArchive {
    param(
        [System.IO.FileInfo]$Archive,
        [string]$Destination
    )

    $extractPath = Join-Path $env:TEMP "gnezdo-extract-$([Guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Force -Path $extractPath | Out-Null

    try {
        Write-Info 'Checking and extracting the selected ZIP...'
        Expand-Archive -LiteralPath $Archive.FullName -DestinationPath $extractPath -Force

        $source = Get-ChildItem -LiteralPath $extractPath -Directory |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'index.html') } |
            Select-Object -First 1

        if ($null -eq $source) {
            $index = Get-ChildItem -LiteralPath $extractPath -Filter 'index.html' -File -Recurse |
                Where-Object { $_.FullName -notmatch '\\(node_modules|dist)\\' } |
                Sort-Object { $_.FullName.Length } |
                Select-Object -First 1

            if ($null -ne $index) {
                $source = $index.Directory
            }
        }

        if ($null -eq $source -or -not (Test-Path -LiteralPath (Join-Path $source.FullName 'scripts\start-gnezdo.ps1'))) {
            throw 'This ZIP is not a valid Hakaton repository archive.'
        }

        New-Item -ItemType Directory -Force -Path $Destination | Out-Null
        Write-Info "Installing archive contents into: $Destination"

        & robocopy.exe $source.FullName $Destination /MIR /XD '.git' /XF '.env' /COPY:DAT /DCOPY:DAT /R:2 /W:1 /NFL /NDL /NJH /NJS /NP
        $robocopyCode = $LASTEXITCODE

        if ($robocopyCode -ge 8) {
            throw "Robocopy failed with code $robocopyCode"
        }

        Write-Host '      Project files were updated successfully.' -ForegroundColor Green
    } finally {
        Remove-Item -LiteralPath $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Stop-PreviousServer {
    param([int]$ServerPort)

    if (Test-Path -LiteralPath $pidFile) {
        $oldPid = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($oldPid -match '^\d+$') {
            Write-Info "Stopping previous server PID $oldPid..."
            Stop-Process -Id ([int]$oldPid) -Force -ErrorAction SilentlyContinue
        }
        Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
    }

    $listeners = Get-NetTCPConnection -LocalPort $ServerPort -State Listen -ErrorAction SilentlyContinue
    foreach ($listener in $listeners) {
        if ($listener.OwningProcess -and $listener.OwningProcess -ne $PID) {
            Write-Info "Freeing port $ServerPort from PID $($listener.OwningProcess)..."
            Stop-Process -Id $listener.OwningProcess -Force -ErrorAction SilentlyContinue
        }
    }
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
        $shortcut.Description = 'Install the newest downloaded Hakaton ZIP and start Gnezdo'
        $shortcut.Save()
        Write-Info 'Desktop shortcut is ready: Gnezdo - Launch'
    } catch {
        Write-Info "Could not create the desktop shortcut: $($_.Exception.Message)"
    }
}

Clear-Host
Write-Host '============================================================' -ForegroundColor DarkGreen
Write-Host '          GNEZDO OFFLINE ARCHIVE LAUNCHER' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor DarkGreen
Write-Host 'No Git or GitHub connection is used by this launcher.' -ForegroundColor Gray

Write-Step 1 'Checking local folders'
Write-Info "Downloads: $DownloadsPath"
Write-Info "Project:   $workDir"

Write-Step 2 'Finding the newest downloaded repository archive'
$archive = Get-LatestHakatonArchive -Path $DownloadsPath

if ($null -eq $archive) {
    Write-Host '      No Hakaton-main ZIP was found in Downloads.' -ForegroundColor Yellow
    if (-not (Test-Path -LiteralPath (Join-Path $workDir 'index.html'))) {
        throw "Download Hakaton-main.zip into $DownloadsPath first."
    }
    Write-Host '      Starting the already installed project.' -ForegroundColor Yellow
} else {
    $archive = Wait-ArchiveReady -Archive $archive
    Write-Host "      Selected: $($archive.Name)" -ForegroundColor Green
    Write-Info "Downloaded: $($archive.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"
}

Write-Step 3 'Installing the archive update'

if ($null -ne $archive) {
    $archiveHash = (Get-FileHash -LiteralPath $archive.FullName -Algorithm SHA256).Hash
    $installedHash = if (Test-Path -LiteralPath $stateFile) {
        (Get-Content -LiteralPath $stateFile -Raw).Trim()
    } else {
        ''
    }

    if ($archiveHash -eq $installedHash -and (Test-Path -LiteralPath (Join-Path $workDir 'index.html'))) {
        Write-Host '      This archive is already installed. No file copy is needed.' -ForegroundColor Green
    } else {
        Install-HakatonArchive -Archive $archive -Destination $workDir
        New-Item -ItemType Directory -Force -Path $stateDirectory | Out-Null
        Set-Content -LiteralPath $stateFile -Value $archiveHash -Encoding ASCII
        Write-Info "Installed archive: $($archive.Name)"
    }
} else {
    Write-Info 'No new local archive to install.'
}

Write-Step 4 'Checking project files'
$indexPath = Join-Path $workDir 'index.html'
$serverPath = Join-Path $workDir 'scripts\serve-static.ps1'

if (-not (Test-Path -LiteralPath $indexPath)) {
    throw "Missing file: $indexPath"
}
if (-not (Test-Path -LiteralPath $serverPath)) {
    throw "Missing file: $serverPath"
}
Write-Info 'Core project files are ready.'

Write-Step 5 'Stopping the previous local server'
Stop-PreviousServer -ServerPort $Port
Write-Info "Port $Port is ready."

Write-Step 6 'Creating the desktop shortcut'
Create-DesktopShortcut -Path $workDir

Write-Step 7 'Starting the ready website'
Write-Host "      URL: http://localhost:$Port" -ForegroundColor Green
Write-Host '      Starting directly on Windows. Docker is not used.' -ForegroundColor Green
Write-Host '      Keep this window open. Press Ctrl+C to stop the server.' -ForegroundColor Yellow
Write-Host ''

& $serverPath -Root $workDir -Port $Port -PidFile $pidFile -OpenBrowser
exit $LASTEXITCODE
