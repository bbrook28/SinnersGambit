# Serves build/web on your home Wi-Fi so a phone can open it. Ctrl+C to stop.
# powershell -ExecutionPolicy Bypass -File tools\serve.ps1 [-Port 8000]
param([int]$Port = 8000)
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\build\web')).Path
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.PrefixOrigin -in 'Dhcp', 'Manual' -and $_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1'
} | Select-Object -First 1).IPAddress
$mime = @{ '.html' = 'text/html'; '.js' = 'application/javascript'; '.wasm' = 'application/wasm';
    '.pck' = 'application/octet-stream'; '.png' = 'image/png'; '.svg' = 'image/svg+xml';
    '.ico' = 'image/x-icon'; '.json' = 'application/json' }
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
try { $listener.Start() } catch {
    Write-Host "Port $Port is already in use (is another serve.ps1 running?). Close it or use -Port 8001."
    exit 1
}
Write-Host "Serving $Root"
Write-Host "On your phone (same Wi-Fi), open:  http://${ip}:$Port/"
try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        try {
            $stream = $client.GetStream()
            $reader = [System.IO.StreamReader]::new($stream)
            $request = $reader.ReadLine()
            while ($true) { $h = $reader.ReadLine(); if ([string]::IsNullOrEmpty($h)) { break } }
            $path = (($request -split ' ')[1] -split '\?')[0]
            if ($path -eq '/') { $path = '/index.html' }
            $file = [System.IO.Path]::GetFullPath((Join-Path $Root ([uri]::UnescapeDataString($path.TrimStart('/')))))
            if ($file.StartsWith($Root) -and (Test-Path $file -PathType Leaf)) {
                $body = [System.IO.File]::ReadAllBytes($file)
                $type = $mime[[System.IO.Path]::GetExtension($file)]
                if (-not $type) { $type = 'application/octet-stream' }
                $status = '200 OK'
            } else {
                $body = [System.Text.Encoding]::UTF8.GetBytes('Not found')
                $type = 'text/plain'
                $status = '404 Not Found'
            }
            $head = "HTTP/1.1 $status`r`nContent-Type: $type`r`nContent-Length: $($body.Length)`r`nCache-Control: no-cache`r`nConnection: close`r`n`r`n"
            $hb = [System.Text.Encoding]::ASCII.GetBytes($head)
            $stream.Write($hb, 0, $hb.Length)
            $stream.Write($body, 0, $body.Length)
            Write-Host "$status $path"
        } catch {
            Write-Host "error: $_"
        } finally {
            $client.Close()
        }
    }
} finally {
    $listener.Stop()
}
