param(
    [Parameter(Mandatory=$true)][string]$Root,
    [int]$Port = 8080,
    [string]$PidFile = "$env:TEMP\gnezdo-local-server.pid"
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

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Prefixes.Add("http://localhost:$Port/")

try {
    $listener.Start()
} catch {
    Write-Host "Не удалось занять порт $Port." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkRed
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
    exit 1
}

Write-Host ""
Write-Host "Гнездо запущено локально" -ForegroundColor Green
Write-Host "Адрес: http://localhost:$Port" -ForegroundColor Cyan
Write-Host "Папка: $Root" -ForegroundColor Gray
Write-Host "Для остановки закройте это окно или нажмите Ctrl+C." -ForegroundColor Yellow
Write-Host ""

function Send-Bytes {
    param($Context, [byte[]]$Bytes, [string]$ContentType, [int]$StatusCode = 200)
    $response = $Context.Response
    $response.StatusCode = $StatusCode
    $response.ContentType = $ContentType
    $response.ContentLength64 = $Bytes.Length
    $response.Headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
    $response.Headers['Pragma'] = 'no-cache'
    $response.Headers['Expires'] = '0'
    $response.OutputStream.Write($Bytes, 0, $Bytes.Length)
    $response.OutputStream.Close()
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        try {
            $rawPath = [System.Uri]::UnescapeDataString($context.Request.Url.AbsolutePath)
            if ([string]::IsNullOrWhiteSpace($rawPath) -or $rawPath -eq '/') {
                $rawPath = '/index.html'
            }

            $relative = $rawPath.TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
            $candidate = [System.IO.Path]::GetFullPath((Join-Path $Root $relative))

            if (-not $candidate.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
                Send-Bytes $context ([Text.Encoding]::UTF8.GetBytes('Forbidden')) 'text/plain; charset=utf-8' 403
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
            $bytes = [System.IO.File]::ReadAllBytes($candidate)
            Send-Bytes $context $bytes $contentType 200
        } catch {
            $message = [Text.Encoding]::UTF8.GetBytes("Local server error: $($_.Exception.Message)")
            try { Send-Bytes $context $message 'text/plain; charset=utf-8' 500 } catch {}
        }
    }
} finally {
    if ($listener.IsListening) { $listener.Stop() }
    $listener.Close()
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
}
