$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$iconDir = Join-Path $repoRoot "frontend\src-tauri\icons"
$svgPath = Join-Path $iconDir "icon.svg"
$pngPath = Join-Path $iconDir "icon-512.png"
$icoPath = Join-Path $iconDir "icon.ico"
$tauriConfigPath = Join-Path $repoRoot "frontend\src-tauri\tauri.conf.json"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

foreach ($path in @($svgPath, $pngPath, $icoPath, $tauriConfigPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Fail "Missing desktop icon file: $path"
  }
}

$svg = Get-Content -LiteralPath $svgPath -Raw -Encoding UTF8
foreach ($token in @("KnowBase", "knowledge cube", "cubeTop", "#5EF2FF", "#6D7CFF", "#B8FF6A")) {
  if (-not $svg.Contains($token)) {
    Fail "Desktop icon SVG does not contain expected brand token: $token"
  }
}

$png = Get-Item -LiteralPath $pngPath
if ($png.Length -lt 10000) {
  Fail "Desktop icon PNG preview is unexpectedly small."
}

$bytes = [System.IO.File]::ReadAllBytes($icoPath)
if ($bytes.Length -lt 20000) {
  Fail "Desktop icon ICO is unexpectedly small."
}

if ([BitConverter]::ToUInt16($bytes, 0) -ne 0 -or [BitConverter]::ToUInt16($bytes, 2) -ne 1) {
  Fail "Desktop icon ICO header is invalid."
}

$entryCount = [BitConverter]::ToUInt16($bytes, 4)
if ($entryCount -lt 6) {
  Fail "Desktop icon ICO should include multiple Windows icon sizes."
}

$config = Get-Content -LiteralPath $tauriConfigPath -Raw -Encoding UTF8
if (-not $config.Contains('"icon": ["icons/icon.ico"]')) {
  Fail "Tauri bundle config is not using the generated desktop icon."
}

Write-Output "Desktop icon checks passed."
