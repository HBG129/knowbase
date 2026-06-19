param(
  [string]$Root = ""
)

$ErrorActionPreference = "Stop"

if (-not $Root) {
  $Root = Split-Path -Parent $PSScriptRoot
}

$rootPath = Resolve-Path -LiteralPath $Root
$scripts = @(
  Get-ChildItem -LiteralPath $rootPath.Path -Filter "*.ps1" -File -ErrorAction Stop
  Get-ChildItem -LiteralPath (Join-Path $rootPath.Path "scripts") -Filter "*.ps1" -File -ErrorAction Stop
)

if ($scripts.Count -eq 0) {
  Write-Output "No PowerShell scripts found."
  exit 0
}

$failed = $false
foreach ($script in $scripts) {
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile(
    $script.FullName,
    [ref]$tokens,
    [ref]$errors
  ) | Out-Null

  if ($errors.Count -gt 0) {
    $failed = $true
    Write-Output "FAIL $($script.FullName)"
    foreach ($errorItem in $errors) {
      Write-Output "  line $($errorItem.Extent.StartLineNumber), column $($errorItem.Extent.StartColumnNumber): $($errorItem.Message)"
    }
  } else {
    Write-Output "PASS $($script.FullName)"
  }
}

if ($failed) {
  exit 1
}

Write-Output "PowerShell script syntax check passed."
