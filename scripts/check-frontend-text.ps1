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
    Path = "frontend\src\lib\i18n.ts"
    Required = @(
      ("API Key " + (U @(0x8BBE, 0x7F6E))),
      (U @(0x667A, 0x8C31)),
      (U @(0x5DF2, 0x914D, 0x7F6E)),
      (U @(0x672A, 0x914D, 0x7F6E, 0x4E2A, 0x4EBA) + " API Key"),
      (U @(0x4FDD, 0x5B58, 0x5931, 0x8D25)),
      (U @(0x53D6, 0x6D88)),
      (U @(0x65E0, 0x6CD5, 0x8FDE, 0x63A5, 0x672C, 0x5730) + " KnowBase " + (U @(0x540E, 0x7AEF))),
      (U @(0x8BF7, 0x5173, 0x95ED, 0x5E94, 0x7528, 0x540E, 0x91CD, 0x65B0, 0x6253, 0x5F00))
    )
  }
)

$forbiddenChecks = @(
  @{
    Path = "frontend\src\app\layout.tsx"
    Forbidden = @(
      "fonts.googleapis.com",
      "fonts.gstatic.com"
    )
  },
  @{
    Path = "frontend\src\lib\api.ts"
    Forbidden = @(
      (U @(0x93C3, 0x72B3, 0x7845))
    )
    ForbiddenCodepoints = @(
      0x93C3,
      0x9225,
      0x951B,
      0x951F,
      0xFFFD
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

foreach ($check in $forbiddenChecks) {
  $path = Join-Path $repoRoot.Path $check.Path
  if (-not (Test-Path -LiteralPath $path)) {
    Fail "Missing frontend text file: $($check.Path)"
  }

  $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
  foreach ($forbidden in $check.Forbidden) {
    if ($content.Contains($forbidden)) {
      Fail "Forbidden frontend text was found in $($check.Path): $forbidden"
    }
  }
  $forbiddenCodepoints = @()
  if ($check.ContainsKey("ForbiddenCodepoints")) {
    $forbiddenCodepoints = $check.ForbiddenCodepoints
  }
  foreach ($codepoint in $forbiddenCodepoints) {
    if ($content.Contains([char]$codepoint)) {
      Fail ("Forbidden frontend text codepoint was found in {0}: U+{1:X4}" -f $check.Path, $codepoint)
    }
  }
}

Write-Output "Frontend text checks passed."
