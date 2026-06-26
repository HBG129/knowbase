$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$libPath = Join-Path $repoRoot "frontend\src-tauri\src\lib.rs"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

if (-not (Test-Path -LiteralPath $libPath)) {
  Fail "Missing Tauri lib file: $libPath"
}

$content = Get-Content -LiteralPath $libPath -Raw -Encoding UTF8

if (-not $content.Contains("tauri::WindowEvent::CloseRequested")) {
  Fail "Tauri window close event does not stop the backend."
}

if (-not $content.Contains("tauri::RunEvent::ExitRequested")) {
  Fail "Tauri app exit-requested event does not stop the backend."
}

if (-not $content.Contains("tauri::RunEvent::Exit")) {
  Fail "Tauri app exit event does not stop the backend."
}

$stopCalls = ([regex]::Matches($content, "\.state::<backend_runtime::BackendProcess>\(\)\s*\.stop\(\)")).Count
if ($stopCalls -lt 2) {
  Fail "Expected backend stop calls for both window close and app exit events."
}

Write-Output "Tauri lifecycle checks passed."
