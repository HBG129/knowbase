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

function Remove-TestDirectory($Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    return
  }

  $resolvedRoot = Resolve-Path -LiteralPath $repoRoot
  $resolvedPath = Resolve-Path -LiteralPath $Path
  if (-not $resolvedPath.Path.StartsWith($resolvedRoot.Path)) {
    Fail "Refusing to remove test directory outside repository: $($resolvedPath.Path)"
  }

  Remove-Item -LiteralPath $resolvedPath.Path -Recurse -Force
}

function Run-ReleaseArtifactSmokeCheck {
  Write-Output ""
  Write-Output "== Release artifact smoke check =="

  $testRoot = Join-Path $repoRoot "data\release-preflight-smoke"
  Remove-TestDirectory $testRoot
  New-Item -ItemType Directory -Force -Path $testRoot | Out-Null

  try {
    $installerPath = Join-Path $testRoot "KnowBase_0.1.0_x64-setup.exe"
    Set-Content -LiteralPath $installerPath -Value "fake installer for release artifact preflight smoke test" -Encoding ASCII

    $zipPath = Join-Path $testRoot "KnowBaseDesktop-Windows-smoke.zip"
    Compress-Archive -LiteralPath $installerPath -DestinationPath $zipPath -Force

    & (Join-Path $PSScriptRoot "check-release-artifact.ps1") -ZipPath $zipPath -MinInstallerBytes 1
    if (-not $?) {
      exit 1
    }
  }
  finally {
    Remove-TestDirectory $testRoot
  }
}

Run-Check "PowerShell script syntax" (Join-Path $PSScriptRoot "check-powershell-scripts.ps1")
Run-Check "Version consistency" (Join-Path $PSScriptRoot "check-version-consistency.ps1")
Run-Check "Sensitive tracked files" (Join-Path $PSScriptRoot "check-sensitive-files.ps1")
Run-Check "Installer hooks" (Join-Path $PSScriptRoot "check-installer-hooks.ps1")
Run-Check "Tauri lifecycle" (Join-Path $PSScriptRoot "check-tauri-lifecycle.ps1")
Run-Check "Desktop windowing" (Join-Path $PSScriptRoot "check-desktop-windowing.ps1")
Run-Check "Desktop icon" (Join-Path $PSScriptRoot "check-desktop-icon.ps1")
Run-Check "Frontend dialogs" (Join-Path $PSScriptRoot "check-frontend-dialogs.ps1")
Run-Check "Frontend localized text" (Join-Path $PSScriptRoot "check-frontend-text.ps1")
Run-Check "Auth UX" (Join-Path $PSScriptRoot "check-auth-ux.ps1")
Run-Check "Chat delete UX" (Join-Path $PSScriptRoot "check-chat-delete-ux.ps1")
Run-Check "Release documentation" (Join-Path $PSScriptRoot "check-release-docs.ps1")
Run-ReleaseArtifactSmokeCheck

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
