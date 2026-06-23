param(
  [string]$DataDir = "",
  [string]$OutputDir = "",
  [switch]$ConfirmBackup
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

if (-not $OutputDir) {
  $desktop = [Environment]::GetFolderPath("Desktop")
  if ($desktop) {
    $OutputDir = Join-Path $desktop "KnowBaseBackups"
  } else {
    $OutputDir = Join-Path $env:TEMP "KnowBaseBackups"
  }
}

$candidate = [System.IO.Path]::GetFullPath($DataDir)
if ((Split-Path -Leaf $candidate) -ne "KnowBase") {
  Fail "Refusing to operate on a directory whose final path segment is not KnowBase: $(Redact-Path $candidate)"
}

$exists = Test-Path -LiteralPath $candidate -PathType Container
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$zipPath = Join-Path $OutputDir "knowbase-data-backup-$timestamp.zip"

Write-Output "KnowBase local data backup plan"
Write-Output "Data directory: $(Redact-Path $candidate)"
Write-Output "Data directory exists: $exists"
Write-Output "Output ZIP: $(Redact-Path $zipPath)"
Write-Output "Credential Manager API keys are not exported by this script."

if (-not $ConfirmBackup) {
  Write-Output ""
  Write-Output "Dry run only. Re-run with -ConfirmBackup to create the ZIP backup."
  exit 0
}

if (-not $exists) {
  Fail "Data directory does not exist: $(Redact-Path $candidate)"
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
if (Test-Path -LiteralPath $zipPath) {
  Fail "Backup ZIP already exists: $(Redact-Path $zipPath)"
}

Compress-Archive -LiteralPath $candidate -DestinationPath $zipPath -CompressionLevel Optimal
$hash = Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath

Write-Output "Backup ZIP created:"
Write-Output (Redact-Path $zipPath)
Write-Output "SHA256: $($hash.Hash)"
Write-Output "Treat this backup as sensitive. It can contain local accounts, document metadata, conversations, uploads, and fallback encrypted API key records."
