# Install the hermes-factory roster onto an existing Hermes install.
# Windows PowerShell. No secrets. Does not start the gateway.
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

$HermesHome = if ($env:HERMES_HOME) { $env:HERMES_HOME } else { Join-Path $HOME ".hermes" }
if (-not (Test-Path $HermesHome)) {
    Die "no Hermes home at $HermesHome. This pack assumes Hermes is already set up."
}

$Profiles = @("chief", "critic", "strategist", "coder", "reviewer")
$Describe = @{
    chief      = "Decomposes work onto the board. Assigns critic, strategist, coder, reviewer. Never implements. Reports results to the human."
    critic     = "Kills bad plans. Finds hidden assumptions, failure modes, missing information, contradictions, and cheaper paths. Does not implement."
    strategist = "Decides what is worth doing and why. Recommendation first. Hands execution to a follow-up card. Does not implement."
    coder      = "Implements the card. Small verified deliverables, tests, tight diffs. Requests review when the card says so."
    reviewer   = "Kills bad code. Reviews diffs and tests. request_changes or approve. Does not rewrite the feature."
}

Write-Host "hermes-factory: installing roster into $HermesHome"
Write-Host ""

foreach ($name in $Profiles) {
    $src = Join-Path $Root "profiles\$name"
    if (-not (Test-Path (Join-Path $src "distribution.yaml"))) {
        Die "missing $src\distribution.yaml"
    }
    $args = @("profile", "install", $src, "--name", $name, "--alias", "-y")
    if ($Force) { $args += "--force" }
    Write-Host "-> hermes $($args -join ' ')"
    & hermes @args
    if ($LASTEXITCODE -ne 0) {
        Die "install failed for $name (rerun with -Force to replace an existing profile)"
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

Write-Host ""
Write-Host "done."
Write-Host ""
Write-Host "Next (you, once):"
Write-Host "  hermes profile use chief"
Write-Host "  hermes gateway start"
Write-Host "  chief chat"
Write-Host ""
Write-Host "Talk to chief. Do not open the board."
