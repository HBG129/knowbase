param(
  [string]$Root = ""
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

if (-not $Root) {
  $Root = Split-Path -Parent $PSScriptRoot
}

$repoRoot = Resolve-Path -LiteralPath $Root
$tauriConfigPath = Join-Path $repoRoot.Path "frontend\src-tauri\tauri.conf.json"

if (-not (Test-Path -LiteralPath $tauriConfigPath)) {
  Fail "Missing Tauri config: $tauriConfigPath"
}

$tauriConfig = Get-Content -LiteralPath $tauriConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
$hooksPathValue = $tauriConfig.bundle.windows.nsis.installerHooks

if (-not $hooksPathValue) {
  Fail "Tauri NSIS installerHooks is not configured."
}

$hooksPath = Join-Path (Split-Path -Parent $tauriConfigPath) $hooksPathValue
if (-not (Test-Path -LiteralPath $hooksPath)) {
  Fail "Configured NSIS installer hooks file does not exist: $hooksPath"
}

$hooks = Get-Content -LiteralPath $hooksPath -Raw -Encoding UTF8
foreach ($required in @("NSIS_HOOK_PREINSTALL", "NSIS_HOOK_PREUNINSTALL", "KnowBase.exe", "KnowBaseBackend.exe", "taskkill")) {
  if (-not $hooks.Contains($required)) {
    Fail "NSIS installer hooks are missing required process cleanup marker: $required"
  }
}

Write-Output "Installer hook checks passed."
