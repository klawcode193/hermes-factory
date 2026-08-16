# Copy the working default model/provider onto factory profiles.
# Does not print keys. Does not overwrite an existing per-profile auth.json.
$ErrorActionPreference = "Stop"

function Resolve-HermesHome {
    if ($env:HERMES_HOME -and (Test-Path $env:HERMES_HOME)) { return $env:HERMES_HOME }
    $candidates = @()
    if ($env:LOCALAPPDATA) { $candidates += (Join-Path $env:LOCALAPPDATA "hermes") }
    $candidates += (Join-Path $HOME ".hermes")
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    throw "no Hermes home found"
}

$HermesHome = Resolve-HermesHome
$Profiles = @("chief", "critic", "strategist", "coder", "reviewer")

$provider = (& hermes -p default config get model.provider 2>$null | Out-String).Trim()
$model = (& hermes -p default config get model.default 2>$null | Out-String).Trim()
if (-not $provider) { $provider = (& hermes config get model.provider 2>$null | Out-String).Trim() }
if (-not $model) { $model = (& hermes config get model.default 2>$null | Out-String).Trim() }
if (-not $provider -and -not $model) { throw "could not read default model. Run hermes -p default model first." }

Write-Host "source: provider=$provider model=$model"
foreach ($name in $Profiles) {
    if ($provider) { & hermes -p $name config set model.provider $provider }
    if ($model) { & hermes -p $name config set model.default $model }
    $srcAuth = Join-Path $HermesHome "auth.json"
    $dstAuth = Join-Path $HermesHome "profiles\$name\auth.json"
    if ((Test-Path $srcAuth) -and -not (Test-Path $dstAuth)) {
        Copy-Item $srcAuth $dstAuth
        Write-Host "copied auth.json to $name (not printed)"
    } else {
        Write-Host "set $name (existing auth.json left alone)"
    }
}

Write-Host ""
Write-Host "Prove it:"
Write-Host '  hermes -p strategist chat -q "Reply with the word alive. Do not load skills."'
