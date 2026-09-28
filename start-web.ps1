param(
    [switch]$Docker,
    [switch]$Local,
    [switch]$NoOpen,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ComposeFile = Join-Path $Root "docker-compose.web.yml"
$Url = "http://localhost:6066"
$script:UseComposeV2 = $false
$script:ComposeExitCode = 0

function Fail([string]$Code, [string]$Message) {
    Write-Host "`n[ERRORE/ERROR $Code] $Message" -ForegroundColor Red
    exit 1
}
function Show-Usage {
    Write-Host @"
PDFGrabber Web

Uso / Usage:
  start-web.bat [--docker|--local] [--no-open]

  --docker   Avvia con Docker (predefinito) / Start with Docker (default)
  --local    Avvia con Python locale / Start with local Python
  --no-open  Non aprire il browser / Do not open the browser
"@
}
function Test-Ready {
    try {
        $response = Invoke-RestMethod -Uri "$Url/api/services" -TimeoutSec 3
        return $null -ne $response.services
    } catch { return $false }
}
function Open-AppBrowser {
    if (-not $NoOpen) { Start-Process $Url }
}
function Ensure-Data {
    foreach ($name in @("config.ini", "db.json")) {
        $path = Join-Path $Root $name
        if ((Test-Path $path) -and -not (Test-Path $path -PathType Leaf)) {
            Fail "PG-START-005" "$name non e un file; nessun dato e stato modificato. / $name is not a file; no data was changed."
        }
    }
    $filesPath = Join-Path $Root "files"
    if ((Test-Path $filesPath) -and -not (Test-Path $filesPath -PathType Container)) {
        Fail "PG-START-005" "files non e una cartella. / files is not a directory."
    }
    if (-not (Test-Path (Join-Path $Root "config.ini"))) {
        Copy-Item (Join-Path $Root "config-default.ini") (Join-Path $Root "config.ini")
    }
    if (-not (Test-Path (Join-Path $Root "db.json"))) { Set-Content (Join-Path $Root "db.json") "{}" }
    if (-not (Test-Path $filesPath)) { New-Item $filesPath -ItemType Directory | Out-Null }
    try { Get-Content (Join-Path $Root "db.json") -Raw | ConvertFrom-Json | Out-Null }
    catch { Fail "PG-START-005" "db.json non contiene JSON valido. / db.json is invalid JSON." }
}
function Invoke-Compose([string[]]$Arguments) {
    $previousErrorAction = $ErrorActionPreference
    try {
        # Windows PowerShell reports normal Docker stderr progress as NativeCommandError.
        $ErrorActionPreference = "Continue"
        if ($script:UseComposeV2) { & docker compose @Arguments } else { & docker-compose @Arguments }
        $script:ComposeExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorAction
    }
}
function Show-DockerDiagnostics {
    Write-Host "`n--- Docker status ---"
    Invoke-Compose @("-f", $ComposeFile, "ps") 2>&1
    Write-Host "`n--- Last logs / Ultimi log ---"
    Invoke-Compose @("-f", $ComposeFile, "logs", "--tail", "80") 2>&1
}
function Start-DockerEngine {
    Write-Host "Docker non e attivo. Provo ad avviarlo... / Docker is not running. Trying to start it..."
    $candidates = @(
        "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
        "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
    )
    $desktop = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($desktop) { Start-Process $desktop }
    Write-Host -NoNewline "Attendo Docker / Waiting for Docker"
    for ($elapsed = 0; $elapsed -lt 120; $elapsed += 2) {
        & docker info *> $null
        if ($LASTEXITCODE -eq 0) { Write-Host " OK"; return $true }
        Write-Host -NoNewline "."; Start-Sleep 2
    }
    Write-Host ""; return $false
}
function Test-Port6066 {
    try {
        $client = New-Object Net.Sockets.TcpClient
        $result = $client.BeginConnect("127.0.0.1", 6066, $null, $null)
        $connected = $result.AsyncWaitHandle.WaitOne(250)
        $client.Close(); return $connected
    } catch { return $false }
}
function Run-Docker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Fail "PG-START-001" "Docker non e installato: https://www.docker.com/products/docker-desktop/ / Docker is not installed."
    }
    & docker info *> $null
    if ($LASTEXITCODE -ne 0 -and -not (Start-DockerEngine)) {
        Fail "PG-START-002" "Docker non si e avviato entro 120 secondi. / Docker did not start within 120 seconds."
    }
    & docker compose version *> $null
    if ($LASTEXITCODE -eq 0) { $script:UseComposeV2 = $true }
    elseif (Get-Command docker-compose -ErrorAction SilentlyContinue) { $script:UseComposeV2 = $false }
    else { Fail "PG-START-003" "Docker Compose non e disponibile. / Docker Compose is unavailable." }
    Ensure-Data
    $frontendId = (Invoke-Compose @("-f", $ComposeFile, "ps", "-q", "frontend") 2>$null | Out-String).Trim()
    if ((Test-Port6066) -and -not $frontendId -and -not (Test-Ready)) {
        Fail "PG-START-004" "La porta 6066 e usata da un altro programma. / Port 6066 is used by another program."
    }
    Write-Host "`nAvvio PDFGrabber con Docker... / Starting PDFGrabber with Docker..."
    $log = Join-Path $Root "pdfgrabber-start.log"
    Invoke-Compose @("-f", $ComposeFile, "up", "-d", "--build") 2>&1 | Tee-Object -FilePath $log
    if ($script:ComposeExitCode -ne 0) {
        Show-DockerDiagnostics
        Fail "PG-START-006" "Docker non ha avviato i servizi. / Docker failed to start the services."
    }
    Write-Host -NoNewline "Attendo il servizio / Waiting for service"
    for ($elapsed = 0; $elapsed -lt 180; $elapsed += 2) {
        if (Test-Ready) { Write-Host " OK"; Open-AppBrowser; Write-Host "`nPDFGrabber e pronto / PDFGrabber is ready: $Url"; return }
        Write-Host -NoNewline "."; Start-Sleep 2
    }
    Write-Host ""; Show-DockerDiagnostics
    Fail "PG-START-007" "PDFGrabber non risponde su $Url. / PDFGrabber is not responding at $Url."
}
function Find-Python {
    if (Get-Command py -ErrorAction SilentlyContinue) { return @("py", "-3") }
    if (Get-Command python -ErrorAction SilentlyContinue) { return @("python") }
    return @()
}
function Invoke-Python([string[]]$Python, [string[]]$Arguments) {
    if ($Python.Count -gt 1) { & $Python[0] $Python[1] @Arguments } else { & $Python[0] @Arguments }
}
function Run-Local {
    Ensure-Data
    if (Test-Ready) { Open-AppBrowser; Write-Host "PDFGrabber e gia pronto / PDFGrabber is already ready: $Url"; return }
    if (Test-Port6066) { Fail "PG-START-004" "La porta 6066 e occupata. / Port 6066 is in use." }
    $python = Find-Python
    if ($python.Count -eq 0) { Fail "PG-START-101" "Python 3.10+ non e installato. / Python 3.10+ is not installed." }
    Invoke-Python $python @("-c", "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)")
    if ($LASTEXITCODE -ne 0) { Fail "PG-START-102" "Serve Python 3.10+. / Python 3.10+ is required." }
    $venvPython = Join-Path $Root "venv\Scripts\python.exe"
    $setupLog = Join-Path $Root "pdfgrabber-setup.log"
    if (-not (Test-Path $venvPython)) {
        Invoke-Python $python @("-m", "venv", (Join-Path $Root "venv")) *> $setupLog
        if ($LASTEXITCODE -ne 0) { Get-Content $setupLog -Tail 40; Fail "PG-START-103" "Creazione ambiente virtuale fallita. / Virtual environment creation failed." }
    }
    & $venvPython -m pip install -r (Join-Path $Root "backend\requirements.txt") *> $setupLog
    if ($LASTEXITCODE -ne 0) { Get-Content $setupLog -Tail 40; Fail "PG-START-104" "Installazione dipendenze fallita. / Dependency installation failed." }
    & $venvPython -m playwright install chromium *>> $setupLog
    if ($LASTEXITCODE -ne 0) { Get-Content $setupLog -Tail 40; Fail "PG-START-105" "Installazione Chromium fallita. / Chromium installation failed." }
    $outLog = Join-Path $Root "server.log"; $errLog = Join-Path $Root "server-error.log"
    $process = Start-Process $venvPython -ArgumentList @("-m", "uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "6066") -WorkingDirectory $Root -RedirectStandardOutput $outLog -RedirectStandardError $errLog -PassThru -NoNewWindow
    for ($elapsed = 0; $elapsed -lt 60; $elapsed++) {
        if (Test-Ready) { break }
        if ($process.HasExited) { Get-Content $errLog -Tail 80; Fail "PG-START-106" "Il server si e arrestato. / The server stopped unexpectedly." }
        Start-Sleep 1
    }
    if (-not (Test-Ready)) { Stop-Process $process -ErrorAction SilentlyContinue; Get-Content $errLog -Tail 80; Fail "PG-START-107" "Il server non risponde. / The server is not responding." }
    Open-AppBrowser
    Write-Host "`nPDFGrabber e pronto / PDFGrabber is ready: $Url"
    Write-Host "Premi Ctrl+C per arrestare / Press Ctrl+C to stop."
    try { Wait-Process $process } finally { if (-not $process.HasExited) { Stop-Process $process } }
}

Set-Location $Root
if ($Help) { Show-Usage; exit 0 }
if ($Docker -and $Local) { Fail "PG-START-000" "Scegli Docker oppure Python. / Choose Docker or Python." }
if (-not $Docker -and -not $Local) {
    $choice = Read-Host "PDFGrabber Web`n`n1) Docker (consigliato / recommended)`n2) Python locale / local Python`n`nScelta / Choice [1]"
    if ($choice -eq "2") { $Local = $true } else { $Docker = $true }
}
if ($Local) { Run-Local } else { Run-Docker }
