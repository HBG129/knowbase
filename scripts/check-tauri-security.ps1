$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $repoRoot "frontend\src-tauri\tauri.conf.json"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

if (-not (Test-Path -LiteralPath $configPath)) {
  Fail "Missing Tauri config: $configPath"
}

$config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$csp = [string]$config.app.security.csp

if ([string]::IsNullOrWhiteSpace($csp)) {
  Fail "Tauri Content Security Policy must not be empty."
}

foreach ($requiredDirective in @(
  "default-src 'self'",
  "script-src 'self'",
  "object-src 'none'",
  "base-uri 'none'",
  "frame-ancestors 'none'",
  "connect-src 'self' ipc: http://ipc.localhost http://127.0.0.1:*"
)) {
  if (-not $csp.Contains($requiredDirective)) {
    Fail "Tauri Content Security Policy is missing: $requiredDirective"
  }
}

foreach ($forbiddenDirective in @(
  "default-src *",
  "script-src *",
  "script-src 'unsafe-eval'",
  "connect-src *"
)) {
  if ($csp.Contains($forbiddenDirective)) {
    Fail "Tauri Content Security Policy contains forbidden directive: $forbiddenDirective"
  }
}

Write-Output "Tauri security checks passed."
