param(
  [switch]$SkipGitStatus
)

$ErrorActionPreference = "Stop"

function Run-Check($Label, $ScriptPath) {
  Write-Output ""
  Write-Output "== $Label =="
  & $ScriptPath
  if (-not $?) {
    exit 1
  }
}

function Fail($Message) {
  Write-Error $Message
  exit 1
}

$repoRoot = Split-Path -Parent $PSScriptRoot

Run-Check "PowerShell script syntax" (Join-Path $PSScriptRoot "check-powershell-scripts.ps1")
Run-Check "Version consistency" (Join-Path $PSScriptRoot "check-version-consistency.ps1")
Run-Check "Sensitive tracked files" (Join-Path $PSScriptRoot "check-sensitive-files.ps1")
Run-Check "Release documentation" (Join-Path $PSScriptRoot "check-release-docs.ps1")

if (-not $SkipGitStatus) {
  Write-Output ""
  Write-Output "== Git status =="
  $status = & git -c "safe.directory=$repoRoot" -C $repoRoot status --porcelain
  if ($LASTEXITCODE -ne 0) {
    Fail "Could not read git status."
  }

  if ($status) {
    $status | ForEach-Object { Write-Output $_ }
    Fail "Git working tree is not clean."
  }

  Write-Output "Git working tree is clean."
}

Write-Output ""
Write-Output "Release preflight checks passed."
