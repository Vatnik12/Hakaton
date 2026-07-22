param(
    [Parameter(Mandatory=$true)][string]$Root,
    [int]$Port = 8080,
    [string]$PidFile = "$env:TEMP\gnezdo-local-server.pid",
    [switch]$OpenBrowser
)

$ErrorActionPreference = 'Stop'
$Root = [System.IO.Path]::GetFullPath($Root)
[System.IO.File]::WriteAllText($PidFile, [string]$PID)

$mime = @{
    '.html' = 'text/html; charset=utf-8'
    '.css'  = 'text/css; charset=utf-8'
    '.js'   = 'application/javascript; charset=utf-8'
    '.json' = 'application/json; charset=utf-8'
    '.svg'  = 'image/svg+xml'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.webp' = 'image/webp'
    '.ico'  = 'image/x-icon'
    '.woff' = 'font/woff'
    '.woff2'= 'font/woff2'
}

function Write-Response {
    param(
        [System.Net.Sockets.NetworkStream]$Stream,
        [byte[]]$Body,
        [string]$ContentType,
        [int]$StatusCode = 200,
        [string]$StatusText = 'OK',
        [bool]$SendBody = $true
    )

    $length = if ($SendBody) { $Body.Length } else { 0 }
    $headers = @(
        "HTTP/1.1 $StatusCode $StatusText"
        "Content-Type: $ContentType"
        "Content-Length: $length"
        'Cache-Control: no-store, no-cache, must-revalidate, max-age=0'
        'Pragma: no-cache'
        'Expires: 0'
        'Connection: close'
        ''
        ''
    ) -join "`r`n"

    $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($headers)
    $Stream.Write($headerBytes, 0, $headerBytes.Length)
    if ($SendBody -and $Body.Length -gt 0) {
        $Stream.Write($Body, 0, $Body.Length)
    }
    $Stream.Flush()
}

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)

try {
    $listener.Start()
} catch {
    Write-Host "[ОШИБКА] Не удалось занять порт $Port." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkRed
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
    exit 1
}

Write-Host ''
Write-Host '============================================================' -ForegroundColor DarkGreen
Write-Host '                 ГНЕЗДО ЗАПУЩЕНО ЛОКАЛЬНО' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor DarkGreen
Write-Host "Адрес:  http://localhost:$Port" -ForegroundColor Cyan
Write-Host "Папка:  $Root" -ForegroundColor Gray
Write-Host "PID:    $PID" -ForegroundColor DarkGray
Write-Host ''
Write-Host 'Ниже отображается журнал запросов браузера.' -ForegroundColor Yellow
Write-Host 'Для остановки нажмите Ctrl+C или закройте окно.' -ForegroundColor Yellow
Write-Host ''

if ($OpenBrowser) {
    Start-Sleep -Milliseconds 350
    try {
        Start-Process "http://localhost:$Port/?dev=$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())"
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Браузер открыт." -ForegroundColor Green
    } catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Не удалось открыть браузер автоматически." -ForegroundColor Yellow
        Write-Host "Откройте вручную: http://localhost:$Port" -ForegroundColor Cyan
    }
}

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        $reader = $null
        $stream = $null
        try {
            $stream = $client.GetStream()
            $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII, $false, 4096, $true)
            $requestLine = $reader.ReadLine()

            if ([string]::IsNullOrWhiteSpace($requestLine)) {
                $body = [System.Text.Encoding]::UTF8.GetBytes('Bad request')
                Write-Response $stream $body 'text/plain; charset=utf-8' 400 'Bad Request'
                continue
            }

            while ($true) {
                $line = $reader.ReadLine()
                if ([string]::IsNullOrEmpty($line)) { break }
            }

            $parts = $requestLine.Split(' ')
            if ($parts.Length -lt 2 -or ($parts[0] -ne 'GET' -and $parts[0] -ne 'HEAD')) {
                $body = [System.Text.Encoding]::UTF8.GetBytes('Method not allowed')
                Write-Response $stream $body 'text/plain; charset=utf-8' 405 'Method Not Allowed'
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 405 $requestLine" -ForegroundColor Yellow
                continue
            }

            $method = $parts[0]
            $urlPath = $parts[1]
            $rawPath = $urlPath.Split('?')[0]
            $rawPath = [System.Uri]::UnescapeDataString($rawPath)
            if ([string]::IsNullOrWhiteSpace($rawPath) -or $rawPath -eq '/') {
                $rawPath = '/index.html'
            }

            $relative = $rawPath.TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
            $candidate = [System.IO.Path]::GetFullPath((Join-Path $Root $relative))

            if (-not $candidate.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
                $body = [System.Text.Encoding]::UTF8.GetBytes('Forbidden')
                Write-Response $stream $body 'text/plain; charset=utf-8' 403 'Forbidden'
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 403 $method $urlPath" -ForegroundColor Red
                continue
            }

            if (Test-Path $candidate -PathType Container) {
                $candidate = Join-Path $candidate 'index.html'
            }

            if (-not (Test-Path $candidate -PathType Leaf)) {
                $candidate = Join-Path $Root 'index.html'
            }

            $extension = [System.IO.Path]::GetExtension($candidate).ToLowerInvariant()
            $contentType = if ($mime.ContainsKey($extension)) { $mime[$extension] } else { 'application/octet-stream' }
            $body = [System.IO.File]::ReadAllBytes($candidate)
            Write-Response $stream $body $contentType 200 'OK' ($method -ne 'HEAD')
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 200 $method $urlPath" -ForegroundColor DarkGray
        } catch {
            try {
                $body = [System.Text.Encoding]::UTF8.GetBytes("Local server error: $($_.Exception.Message)")
                if ($stream) { Write-Response $stream $body 'text/plain; charset=utf-8' 500 'Internal Server Error' }
            } catch {}
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 500 $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            if ($reader) { $reader.Dispose() }
            if ($stream) { $stream.Dispose() }
            $client.Close()
        }
    }
} finally {
    $listener.Stop()
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
    Write-Host ''
    Write-Host 'Локальный сервер остановлен.' -ForegroundColor Yellow
}
