param(
  [Parameter(Mandatory = $true)]
  [string]$ZipPath,

  [string]$ExpectedSha256 = "",

  [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $OutputDir) {
  $workspaceRoot = Split-Path -Parent $repoRoot
  $OutputDir = Join-Path $workspaceRoot "artifacts\knowbase-release"
}

$zip = Resolve-Path -LiteralPath $ZipPath -ErrorAction SilentlyContinue
if (-not $zip) {
  Fail "Release artifact ZIP was not found: $ZipPath"
}

& (Join-Path $PSScriptRoot "check-release-artifact.ps1") -ZipPath $zip.Path -ExpectedSha256 $ExpectedSha256

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($zip.Path)
try {
  $installer = @(
    $archive.Entries |
      Where-Object { $_.FullName -match '(^|/|\\)KnowBase_.*_x64-setup\.exe$' -and $_.Length -gt 0 }
  )[0]

  $installerPath = Join-Path $OutputDir (Split-Path -Leaf $installer.FullName)
  [System.IO.Compression.ZipFileExtensions]::ExtractToFile($installer, $installerPath, $true)
}
finally {
  $archive.Dispose()
}

$zipHash = Get-FileHash -Algorithm SHA256 -LiteralPath $zip.Path
$installerHash = Get-FileHash -Algorithm SHA256 -LiteralPath $installerPath
$checksumPath = Join-Path $OutputDir "SHA256SUMS.txt"
$summaryPath = Join-Path $OutputDir "RELEASE_ARTIFACTS.md"
$installerName = Split-Path -Leaf $installerPath
$zipName = Split-Path -Leaf $zip.Path

$checksums = @(
  "$($installerHash.Hash)  $installerName"
  "$($zipHash.Hash)  $zipName"
)
Set-Content -LiteralPath $checksumPath -Value $checksums -Encoding ASCII

$summary = @(
  '# KnowBase Release Artifacts'
  ''
  "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
  ''
  '## Files'
  ''
  "- Installer: ``$installerName``"
  "- Source ZIP artifact: ``$zipName``"
  '- Checksums: `SHA256SUMS.txt`'
  ''
  '## SHA256'
  ''
  '```text'
  $checksums
  '```'
  ''
  '## Next Step'
  ''
  'Install the setup executable on a clean Windows machine and follow `docs\clean-machine-validation.md`.'
)
Set-Content -LiteralPath $summaryPath -Value $summary -Encoding ASCII

Write-Output "Release package prepared."
Write-Output "Output: $OutputDir"
Write-Output "Installer: $installerPath"
Write-Output "Checksums: $checksumPath"
Write-Output "Summary: $summaryPath"
