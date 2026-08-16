# Install the hermes-specialists roster onto an existing Hermes install.
# Windows PowerShell. No secrets. Does not start the gateway.
# Idempotent: existing profiles are updated in place (config.yaml kept).
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Die([string]$Message) {
    Write-Error $Message
    exit 1
}

if (-not (Get-Command hermes -ErrorAction SilentlyContinue)) {
    Die "hermes is not on PATH. Install Hermes first, then rerun."
}

$ver = (& hermes --version 2>$null | Out-String).Trim()
Write-Host "hermes: $(if ($ver) { $ver } else { 'unknown' })"
$m = [regex]::Match($ver, '(\d+)\.(\d+)')
if ($m.Success) {
    $major = [int]$m.Groups[1].Value
    $minor = [int]$m.Groups[2].Value
    if ($major -eq 0 -and $minor -lt 19) {
        Die "need Hermes >= 0.19, got $ver"
    }
}

function Resolve-HermesHome {
    if ($env:HERMES_HOME -and (Test-Path $env:HERMES_HOME)) { return $env:HERMES_HOME }
    $candidates = @()
    if ($env:LOCALAPPDATA) { $candidates += (Join-Path $env:LOCALAPPDATA "hermes") }
    $candidates += (Join-Path $HOME ".hermes")
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

$HermesHome = Resolve-HermesHome
if (-not $HermesHome) {
    Die "no Hermes home found. Checked %LOCALAPPDATA%\hermes and ~/.hermes. This pack assumes Hermes is already set up."
}

$Profiles = @("chief", "critic", "strategist", "coder", "reviewer")
$Describe = @{
    chief      = "Decomposes work onto the board. Assigns critic, strategist, coder, reviewer. Never implements. Reports results to the human."
    critic     = "Kills bad plans. Finds hidden assumptions, failure modes, missing information, contradictions, and cheaper paths. Does not implement."
    strategist = "Decides what is worth doing and why. Recommendation first. Hands execution to a follow-up card. Does not implement."
    coder      = "Implements the card. Small verified deliverables, tests, tight diffs. Requests review when the card says so."
    reviewer   = "Kills bad code. Reviews diffs and tests. request_changes or approve. Does not rewrite the feature."
}

Write-Host "hermes-specialists: installing roster into $HermesHome"
Write-Host ""

foreach ($name in $Profiles) {
    $src = Join-Path $Root "profiles\$name"
    if (-not (Test-Path (Join-Path $src "distribution.yaml"))) {
        Die "missing $src\distribution.yaml"
    }
    $installArgs = @("profile", "install", $src, "--name", $name, "--alias", "-y")
    if ($Force) { $installArgs += "--force" }
    Write-Host "-> hermes $($installArgs -join ' ')"
    & hermes @installArgs
    if ($LASTEXITCODE -ne 0) {
        if ($Force) { Die "install failed for $name even with -Force" }
        Write-Host "   profile $name exists. Updating in place (keeps your config.yaml / chat ids)."
        & hermes profile update $name
        if ($LASTEXITCODE -ne 0) {
            Die "update failed for $name. If you really want a clean overwrite: .\install.ps1 -Force (this can replace config.yaml)"
        }
    }
}

Write-Host ""
Write-Host "-> writing kanban routing descriptions"
foreach ($name in $Profiles) {
    & hermes profile describe $name --text $Describe[$name]
}

Write-Host ""
Write-Host "-> pointing the default config at chief as orchestrator"
& hermes config set kanban.orchestrator_profile chief
& hermes config set kanban.dispatch_in_gateway true
& hermes config set kanban.auto_decompose true
& hermes config set kanban.auto_subscribe_on_create true

Write-Host ""
Write-Host "-> hermes kanban init"
& hermes kanban init
if ($LASTEXITCODE -ne 0) { Die "hermes kanban init failed (exit $LASTEXITCODE). Fix the board, then rerun. Do not continue." }


Write-Host ""
Write-Host "-> pinning workers to the model that already works on default"
$provider = (& hermes -p default config get model.provider 2>$null | Out-String).Trim()
$model = (& hermes -p default config get model.default 2>$null | Out-String).Trim()
if (-not $provider) { $provider = (& hermes config get model.provider 2>$null | Out-String).Trim() }
if (-not $model) { $model = (& hermes config get model.default 2>$null | Out-String).Trim() }
if ($provider -or $model) {
    Write-Host "   source: provider=$provider model=$model"
    foreach ($name in $Profiles) {
        if ($provider) { & hermes -p $name config set model.provider $provider }
        if ($model) { & hermes -p $name config set model.default $model }
        $srcAuth = Join-Path $HermesHome "auth.json"
        $dstAuth = Join-Path $HermesHome "profiles\$name\auth.json"
        if ((Test-Path $srcAuth) -and -not (Test-Path $dstAuth)) {
            Copy-Item $srcAuth $dstAuth
            Write-Host "   copied auth.json to $name (not printed)"
        }
    }
} else {
    Write-Host "   could not read default model. Run .\\setup-models.ps1 after you know which provider works."
}

Write-Host ""
Write-Host "done."
Write-Host ""
Write-Host "Next:"
Write-Host "  1. Stop the default gateway if it is running. One dispatcher."
Write-Host "  2. hermes profile use chief   (this changes your current profile)"
Write-Host "  3. hermes -p chief gateway start"
Write-Host "     New profile = new Windows service. If it asks to install, Y."
Write-Host "     UAC opens in another window. Approve it, then start again if status is down."
Write-Host "  4. hermes -p strategist chat -q \"Reply with the word alive. Do not load skills.\""
Write-Host "  5. Talk only to chief. Telegram: .\setup-telegram.ps1"
Write-Host "  6. Do not open the board."
Write-Host ""
Write-Host "If Telegram chief says it has no kanban tools: add kanban to platform_toolsets.telegram"
Write-Host "in chief config.yaml. Merge. Do not replace a file that has chat ids."
