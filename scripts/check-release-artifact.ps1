param(
  [Parameter(Mandatory = $true)]
  [string]$ZipPath,

  [string]$ExpectedSha256 = ""
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

$resolvedZip = Resolve-Path -LiteralPath $ZipPath -ErrorAction SilentlyContinue
if (-not $resolvedZip) {
  Fail "Release artifact ZIP was not found: $ZipPath"
}

$zipItem = Get-Item -LiteralPath $resolvedZip.Path
if ($zipItem.Length -le 0) {
  Fail "Release artifact ZIP is empty: $($zipItem.FullName)"
}

$hash = Get-FileHash -Algorithm SHA256 -LiteralPath $zipItem.FullName
if ($ExpectedSha256) {
  $expected = $ExpectedSha256.ToUpperInvariant()
  if ($hash.Hash.ToUpperInvariant() -ne $expected) {
    Fail "SHA256 mismatch. Expected $expected but got $($hash.Hash)."
  }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($zipItem.FullName)
try {
  $installers = @(
    $zip.Entries |
      Where-Object { $_.FullName -match '(^|/|\\)KnowBase_.*_x64-setup\.exe$' -and $_.Length -gt 0 }
  )

  if ($installers.Count -ne 1) {
    Fail "Expected exactly one KnowBase x64 setup exe in the ZIP, found $($installers.Count)."
  }

  $installer = $installers[0]
  if ($installer.Length -lt 50000000) {
    Fail "Installer looks too small: $($installer.Length) bytes."
  }

  Write-Output "Release artifact verified."
  Write-Output "ZIP: $($zipItem.FullName)"
  Write-Output "ZIP SHA256: $($hash.Hash)"
  Write-Output "Installer: $($installer.FullName)"
  Write-Output "Installer bytes: $($installer.Length)"
}
finally {
  $zip.Dispose()
}
