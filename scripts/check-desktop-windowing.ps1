$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$mainPath = Join-Path $repoRoot "frontend\src-tauri\src\main.rs"
$backendRuntimePath = Join-Path $repoRoot "frontend\src-tauri\src\backend_runtime.rs"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

function Read-File($Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    Fail "Missing file: $Path"
  }
  Get-Content -LiteralPath $Path -Raw -Encoding UTF8
}

$main = Read-File $mainPath
$backendRuntime = Read-File $backendRuntimePath

if (-not $main.Contains('windows_subsystem = "windows"')) {
  Fail "Release Tauri app is not configured for the Windows GUI subsystem."
}

if (-not $backendRuntime.Contains("std::os::windows::process::CommandExt")) {
  Fail "Backend process launcher does not import Windows CommandExt."
}

if (-not $backendRuntime.Contains("CREATE_NO_WINDOW")) {
  Fail "Backend process launcher does not define CREATE_NO_WINDOW."
}

if (-not $backendRuntime.Contains(".creation_flags(CREATE_NO_WINDOW)")) {
  Fail "Backend process launcher does not hide the backend console window."
}

Write-Output "Desktop windowing checks passed."
