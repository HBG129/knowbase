param(
  [string]$DataDir = "",
  [switch]$ConfirmDelete
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

function Get-KnowBaseCredentialTargets() {
  $output = & cmdkey /list 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $output) {
    return @()
  }

  $targets = New-Object System.Collections.Generic.List[string]
  foreach ($line in $output) {
    if ($line -match '(KnowBase:user:[^ \t\r\n]+:llm-api-key)') {
      $targets.Add($Matches[1])
    }
  }
  return @($targets | Sort-Object -Unique)
}

if (-not $DataDir) {
  if (-not $env:APPDATA) {
    Fail "APPDATA is not set and no -DataDir was provided."
  }
  $DataDir = Join-Path $env:APPDATA "KnowBase"
}

$candidate = [System.IO.Path]::GetFullPath($DataDir)
if ((Split-Path -Leaf $candidate) -ne "KnowBase") {
  Fail "Refusing to operate on a directory whose final path segment is not KnowBase: $(Redact-Path $candidate)"
}

$exists = Test-Path -LiteralPath $candidate
$credentialTargets = Get-KnowBaseCredentialTargets

Write-Output "KnowBase local data removal plan"
Write-Output "Data directory: $(Redact-Path $candidate)"
Write-Output "Data directory exists: $exists"
Write-Output "Credential targets found: $($credentialTargets.Count)"
foreach ($target in $credentialTargets) {
  Write-Output "  $target"
}

if (-not $ConfirmDelete) {
  Write-Output ""
  Write-Output "Dry run only. Re-run with -ConfirmDelete to remove the data directory and KnowBase credential targets."
  exit 0
}

if ($exists) {
  Remove-Item -LiteralPath $candidate -Recurse -Force
  Write-Output "Removed data directory: $(Redact-Path $candidate)"
} else {
  Write-Output "Data directory did not exist."
}

foreach ($target in $credentialTargets) {
  & cmdkey /delete:$target | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Fail "Failed to delete credential target: $target"
  }
  Write-Output "Removed credential target: $target"
}
