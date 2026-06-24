param(
  [string]$Root = ""
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

function U([int[]]$Codes) {
  return -join ($Codes | ForEach-Object { [char]$_ })
}

if (-not $Root) {
  $Root = Split-Path -Parent $PSScriptRoot
}

$repoRoot = Resolve-Path -LiteralPath $Root
$checks = @(
  @{
    Path = "frontend\src\components\auth\api-key-dialog.tsx"
    Required = @(
      ("API Key " + (U @(0x8BBE, 0x7F6E))),
      (U @(0x667A, 0x8C31)),
      (U @(0x5DF2, 0x914D, 0x7F6E)),
      (U @(0x672A, 0x914D, 0x7F6E, 0x4E2A, 0x4EBA) + " API Key"),
      (U @(0x4FDD, 0x5B58, 0x5931, 0x8D25)),
      (U @(0x53D6, 0x6D88))
    )
  }
)

foreach ($check in $checks) {
  $path = Join-Path $repoRoot.Path $check.Path
  if (-not (Test-Path -LiteralPath $path)) {
    Fail "Missing frontend text file: $($check.Path)"
  }

  $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
  foreach ($required in $check.Required) {
    if (-not $content.Contains($required)) {
      Fail "Expected clean localized text was not found in $($check.Path)."
    }
  }
}

Write-Output "Frontend text checks passed."
