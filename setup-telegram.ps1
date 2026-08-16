# Move TELEGRAM_BOT_TOKEN from default Hermes onto chief.
# Does not print the token. Run in local PowerShell, not in the Telegram chat.
$ErrorActionPreference = "Stop"

function Resolve-HermesHome {
    if ($env:HERMES_HOME -and (Test-Path $env:HERMES_HOME)) { return $env:HERMES_HOME }
    $candidates = @()
    if ($env:LOCALAPPDATA) { $candidates += (Join-Path $env:LOCALAPPDATA "hermes") }
    $candidates += (Join-Path $HOME ".hermes")
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    throw "no Hermes home found"
}

$home = Resolve-HermesHome
$defaultEnv = Join-Path $home ".env"
$chiefDir = Join-Path $home "profiles\chief"
$chiefEnv = Join-Path $chiefDir ".env"

if (-not (Test-Path $chiefDir)) { throw "chief profile missing at $chiefDir. Run .\install.ps1 first." }

Write-Host "hermes home: $home"
& hermes profile list

$defaultLine = $null
if (Test-Path $defaultEnv) {
    $defaultLine = Get-Content $defaultEnv | Where-Object { $_ -match '^\s*TELEGRAM_BOT_TOKEN=' }
}
$chiefHas = (Test-Path $chiefEnv) -and ((Get-Content $chiefEnv | Where-Object { $_ -match '^\s*TELEGRAM_BOT_TOKEN=' }))

if (-not $defaultLine -and $chiefHas) {
    Write-Host "token already on chief only. Leaving default gateway alone."
} elseif (-not $defaultLine -and -not $chiefHas) {
    throw "no TELEGRAM_BOT_TOKEN in default .env or chief .env"
} else {
    Write-Host "stopping default gateway (it still holds the token)"
    & hermes -p default gateway stop
    if (-not (Test-Path $chiefEnv)) { New-Item -ItemType File -Path $chiefEnv | Out-Null }
    $chief = @(Get-Content $chiefEnv | Where-Object { $_ -notmatch '^\s*TELEGRAM_BOT_TOKEN=' })
    $chief += $defaultLine
    Set-Content $chiefEnv $chief
    Set-Content $defaultEnv (Get-Content $defaultEnv | Where-Object { $_ -notmatch '^\s*TELEGRAM_BOT_TOKEN=' })
    Write-Host "token moved (value not printed)"
}

& hermes -p chief gateway start
& hermes profile use chief
& hermes -p chief gateway status
Write-Host "Message the same Telegram bot. That should be chief."
