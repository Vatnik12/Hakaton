param(
    [Parameter(Mandatory = $true)]
    [string]$Root,

    [int]$Port = 8080,

    [string]$PidFile = "$env:TEMP\gnezdo-local-server.pid",

    [switch]$OpenBrowser
)

$ErrorActionPreference = 'Stop'
$Root = [System.IO.Path]::GetFullPath($Root)
[System.IO.File]::WriteAllText($PidFile, [string]$PID)

$mime = @{
    '.html'  = 'text/html; charset=utf-8'
    '.css'   = 'text/css; charset=utf-8'
    '.js'    = 'application/javascript; charset=utf-8'
    '.json'  = 'application/json; charset=utf-8'
    '.svg'   = 'image/svg+xml'
    '.png'   = 'image/png'
    '.jpg'   = 'image/jpeg'
    '.jpeg'  = 'image/jpeg'
    '.webp'  = 'image/webp'
    '.ico'   = 'image/x-icon'
    '.woff'  = 'font/woff'
    '.woff2' = 'font/woff2'
    '.txt'   = 'text/plain; charset=utf-8'
    '.map'   = 'application/json; charset=utf-8'
}

function Write-Response {
    param(
        [System.Net.Sockets.NetworkStream]$Stream,
        [byte[]]$Body,
        [string]$ContentType,
        [int]$StatusCode = 200,
        [string]$StatusText = 'OK',
        [long]$ContentLength = -1
    )

    if ($ContentLength -lt 0) {
        $ContentLength = $Body.Length
    }

    $headers = @(
        "HTTP/1.1 $StatusCode $StatusText"
        "Content-Type: $ContentType"
        "Content-Length: $ContentLength"
        'Cache-Control: no-store, no-cache, must-revalidate, max-age=0'
        'Pragma: no-cache'
        'Expires: 0'
        'Connection: close'
        ''
        ''
    ) -join "`r`n"

    $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($headers)
    $Stream.Write($headerBytes, 0, $headerBytes.Length)

    if ($Body.Length -gt 0) {
        $Stream.Write($Body, 0, $Body.Length)
    }

    $Stream.Flush()
}

function Write-RequestLog {
    param(
        [string]$Method,
        [string]$Path,
        [int]$StatusCode
    )

    $time = Get-Date -Format 'HH:mm:ss'
    $color = if ($StatusCode -ge 500) { 'Red' } elseif ($StatusCode -ge 400) { 'Yellow' } else { 'DarkGray' }
    Write-Host "[$time] $StatusCode $Method $Path" -ForegroundColor $color
}

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)

try {
    $listener.Start()
} catch {
    Write-Host ''
    Write-Host "Не удалось занять порт $Port." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkRed
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
    exit 1
}

Write-Host ''
Write-Host '============================================================' -ForegroundColor DarkGreen
Write-Host '                ГНЕЗДО ЗАПУЩЕНО ЛОКАЛЬНО' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor DarkGreen
Write-Host "Адрес: http://localhost:$Port" -ForegroundColor Cyan
Write-Host "Папка: $Root" -ForegroundColor Gray
Write-Host "PID: $PID" -ForegroundColor DarkGray
Write-Host 'Ниже отображаются запросы браузера.' -ForegroundColor Gray
Write-Host 'Для остановки нажмите Ctrl+C или закройте окно.' -ForegroundColor Yellow
Write-Host ''

if ($OpenBrowser) {
    Start-Sleep -Milliseconds 350
    Start-Process "http://localhost:$Port/?dev=$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())"
}

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        $reader = $null
        $stream = $null
        $method = '?'
        $requestPath = '/'
        $statusCode = 500

        try {
            $stream = $client.GetStream()
            $reader = [System.IO.StreamReader]::new(
                $stream,
                [System.Text.Encoding]::ASCII,
                $false,
                4096,
                $true
            )

            $requestLine = $reader.ReadLine()

            if ([string]::IsNullOrWhiteSpace($requestLine)) {
                $body = [System.Text.Encoding]::UTF8.GetBytes('Bad request')
                Write-Response $stream $body 'text/plain; charset=utf-8' 400 'Bad Request'
                $statusCode = 400
                continue
            }

            while ($true) {
                $line = $reader.ReadLine()
                if ([string]::IsNullOrEmpty($line)) { break }
            }

            $parts = $requestLine.Split(' ')
            if ($parts.Length -lt 2) {
                $body = [System.Text.Encoding]::UTF8.GetBytes('Bad request')
                Write-Response $stream $body 'text/plain; charset=utf-8' 400 'Bad Request'
                $statusCode = 400
                continue
            }

            $method = $parts[0]
            $requestPath = $parts[1].Split('?')[0]

            if ($method -ne 'GET' -and $method -ne 'HEAD') {
                $body = [System.Text.Encoding]::UTF8.GetBytes('Method not allowed')
                Write-Response $stream $body 'text/plain; charset=utf-8' 405 'Method Not Allowed'
                $statusCode = 405
                continue
            }

            $rawPath = [System.Uri]::UnescapeDataString($requestPath)
            if ([string]::IsNullOrWhiteSpace($rawPath) -or $rawPath -eq '/') {
                $rawPath = '/index.html'
            }

            if ($rawPath.StartsWith('/api/')) {
                $json = '{"status":"offline","message":"Локальная статическая версия запущена без Spring Boot"}'
                $fullBody = [System.Text.Encoding]::UTF8.GetBytes($json)
                $body = if ($method -eq 'HEAD') { [byte[]]::new(0) } else { $fullBody }
                Write-Response $stream $body 'application/json; charset=utf-8' 503 'Service Unavailable' $fullBody.Length
                $statusCode = 503
                continue
            }

            $relative = $rawPath.TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
            $candidate = [System.IO.Path]::GetFullPath((Join-Path $Root $relative))

            if (-not $candidate.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
                $body = [System.Text.Encoding]::UTF8.GetBytes('Forbidden')
                Write-Response $stream $body 'text/plain; charset=utf-8' 403 'Forbidden'
                $statusCode = 403
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
            $fullBody = [System.IO.File]::ReadAllBytes($candidate)
            $body = if ($method -eq 'HEAD') { [byte[]]::new(0) } else { $fullBody }

            Write-Response $stream $body $contentType 200 'OK' $fullBody.Length
            $statusCode = 200
        } catch {
            $statusCode = 500
            try {
                $body = [System.Text.Encoding]::UTF8.GetBytes("Local server error: $($_.Exception.Message)")
                Write-Response $stream $body 'text/plain; charset=utf-8' 500 'Internal Server Error'
            } catch {}
        } finally {
            Write-RequestLog $method $requestPath $statusCode
            if ($reader) { $reader.Dispose() }
            if ($stream) { $stream.Dispose() }
            $client.Close()
        }
    }
} finally {
    $listener.Stop()
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
}
