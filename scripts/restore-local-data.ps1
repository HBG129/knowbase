param(
  [Parameter(Mandatory = $true)]
  [string]$ZipPath,

  [string]$DataDir = "",

  [switch]$ConfirmRestore
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

function Redact-Path($Path) {
  $value = [string]$Path
  if ($env:USERPROFILE) {
    $value = $value.Replace($env:USERPROFILE, "%USERPROFILE%")
  }
  if ($env:APPDATA) {
    $value = $value.Replace($env:APPDATA, "%APPDATA%")
  }
  return $value
}

if (-not $DataDir) {
  if (-not $env:APPDATA) {
    Fail "APPDATA is not set and no -DataDir was provided."
  }
  $DataDir = Join-Path $env:APPDATA "KnowBase"
}

$resolvedZip = Resolve-Path -LiteralPath $ZipPath -ErrorAction SilentlyContinue
if (-not $resolvedZip) {
  Fail "Backup ZIP was not found: $ZipPath"
}

$target = [System.IO.Path]::GetFullPath($DataDir)
if ((Split-Path -Leaf $target) -ne "KnowBase") {
  Fail "Refusing to operate on a directory whose final path segment is not KnowBase: $(Redact-Path $target)"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($resolvedZip.Path)
try {
  $hasKnowBaseRoot = $false
  foreach ($entry in $archive.Entries) {
    if ($entry.FullName -match '^(KnowBase/|KnowBase\\)') {
      $hasKnowBaseRoot = $true
      break
    }
  }
  if (-not $hasKnowBaseRoot) {
    Fail "Backup ZIP does not contain a top-level KnowBase folder."
  }
}
finally {
  $archive.Dispose()
}

$targetExists = Test-Path -LiteralPath $target
$parent = Split-Path -Parent $target

Write-Output "KnowBase local data restore plan"
Write-Output "Backup ZIP: $(Redact-Path $resolvedZip.Path)"
Write-Output "Target data directory: $(Redact-Path $target)"
Write-Output "Target exists: $targetExists"
Write-Output "Credential Manager API keys are not restored by this script."

if (-not $ConfirmRestore) {
  Write-Output ""
  Write-Output "Dry run only. Re-run with -ConfirmRestore to restore the ZIP into the target parent directory."
  exit 0
}

if ($targetExists) {
  Fail "Target data directory already exists. Back it up and remove it before restore: $(Redact-Path $target)"
}

New-Item -ItemType Directory -Force -Path $parent | Out-Null
[System.IO.Compression.ZipFile]::ExtractToDirectory($resolvedZip.Path, $parent)

if (-not (Test-Path -LiteralPath $target -PathType Container)) {
  Fail "Restore finished but target directory was not created: $(Redact-Path $target)"
}

Write-Output "Restored KnowBase data directory:"
Write-Output (Redact-Path $target)
Write-Output "Add the provider API key again in the app if this restore is on a different Windows profile or machine."
