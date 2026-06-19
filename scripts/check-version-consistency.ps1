$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

function Get-RegexValue($Path, $Pattern, $Name) {
  $text = Get-Content -LiteralPath $Path -Raw
  $match = [regex]::Match($text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
  if (-not $match.Success) {
    Fail "Could not find $Name in $Path"
  }

  return $match.Groups[1].Value
}

$repoRoot = Split-Path -Parent $PSScriptRoot

$backendPyproject = Join-Path $repoRoot "backend\pyproject.toml"
$cargoToml = Join-Path $repoRoot "frontend\src-tauri\Cargo.toml"
$tauriConfigPath = Join-Path $repoRoot "frontend\src-tauri\tauri.conf.json"
$releaseScript = Join-Path $repoRoot "scripts\prepare-release-package.ps1"

$backendVersion = Get-RegexValue $backendPyproject '^\s*version\s*=\s*"([^"]+)"\s*$' "backend version"
$cargoVersion = Get-RegexValue $cargoToml '^\s*version\s*=\s*"([^"]+)"\s*$' "Cargo package version"
$tauriConfig = Get-Content -LiteralPath $tauriConfigPath -Raw | ConvertFrom-Json
$tauriVersion = [string]$tauriConfig.version
$releaseVersion = Get-RegexValue $releaseScript '^\s*\[string\]\$Version\s*=\s*"([^"]+)"\s*,?\s*$' "release script default version"

if (-not $tauriVersion) {
  Fail "Could not find Tauri app version in $tauriConfigPath"
}

$appVersions = [ordered]@{
  "backend pyproject" = $backendVersion
  "Cargo package" = $cargoVersion
  "Tauri config" = $tauriVersion
}

foreach ($entry in $appVersions.GetEnumerator()) {
  Write-Output "$($entry.Key): $($entry.Value)"
}
Write-Output "release default: $releaseVersion"

$expectedAppVersion = $backendVersion
foreach ($entry in $appVersions.GetEnumerator()) {
  if ($entry.Value -ne $expectedAppVersion) {
    Fail "Version mismatch: $($entry.Key) is $($entry.Value), expected $expectedAppVersion"
  }
}

$releasePrefix = "$expectedAppVersion-"
if (($releaseVersion -ne $expectedAppVersion) -and (-not $releaseVersion.StartsWith($releasePrefix))) {
  Fail "Release default version $releaseVersion does not match app version $expectedAppVersion"
}

Write-Output "Version consistency check passed."
