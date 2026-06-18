param(
  [string]$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$backendExe = Join-Path $Root "backend\dist\KnowBaseBackend.exe"
$bundleDir = Join-Path $Root "frontend\src-tauri\target\release\bundle"
$nsisDir = Join-Path $bundleDir "nsis"

if (-not (Test-Path -LiteralPath $backendExe -PathType Leaf)) {
  throw "Missing backend executable: $backendExe"
}

if (-not (Test-Path -LiteralPath $bundleDir -PathType Container)) {
  throw "Missing desktop bundle directory: $bundleDir"
}

if (-not (Test-Path -LiteralPath $nsisDir -PathType Container)) {
  throw "Missing NSIS installer directory: $nsisDir"
}

$installers = @(Get-ChildItem -LiteralPath $nsisDir -Filter "*.exe" -File)
if ($installers.Count -eq 0) {
  throw "No NSIS installer .exe files found in: $nsisDir"
}

Write-Host "Desktop artifacts verified."
Write-Host "Backend executable:"
Write-Host "  $backendExe"
Write-Host "NSIS installers:"
foreach ($installer in $installers) {
  Write-Host ("  {0} ({1} bytes)" -f $installer.FullName, $installer.Length)
}
