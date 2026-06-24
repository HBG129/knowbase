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
$dialogPath = Join-Path $repoRoot.Path "frontend\src\components\kb\kb-create-dialog.tsx"

if (-not (Test-Path -LiteralPath $dialogPath)) {
  Fail "Missing KB create dialog: $dialogPath"
}

$content = Get-Content -LiteralPath $dialogPath -Raw

if ($content -notmatch 'createPortal') {
  Fail "KB create dialog must render through createPortal so it is not clipped by page sections."
}

if ($content -notmatch 'fixed inset-0') {
  Fail "KB create dialog must use a fixed viewport overlay."
}

if ($content -match 'absolute\s+right-0\s+top-full') {
  Fail "KB create dialog still uses dropdown positioning that can be clipped or misaligned."
}

Write-Output "Frontend dialog checks passed."
