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
$workspaceTempRoot = Join-Path (Split-Path -Parent $repoRoot) ".tmp"

function Remove-TestDirectory($Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    return
  }

  if (-not (Test-Path -LiteralPath $workspaceTempRoot)) {
    return
  }

  $resolvedRoot = Resolve-Path -LiteralPath $workspaceTempRoot
  $resolvedPath = Resolve-Path -LiteralPath $Path
  if (-not $resolvedPath.Path.StartsWith($resolvedRoot.Path)) {
    Fail "Refusing to remove test directory outside workspace temp directory: $($resolvedPath.Path)"
  }

  Remove-Item -LiteralPath $resolvedPath.Path -Recurse -Force
}

function Run-ReleaseArtifactSmokeCheck {
  Write-Output ""
  Write-Output "== Release artifact smoke check =="

  function Get-AuthenticodeSignature {
    param(
      [Parameter(Mandatory = $true)]
      [string]$LiteralPath
    )

    return [pscustomobject]@{
      Status = "NotSigned"
      SignerCertificate = $null
    }
  }

  $testRoot = Join-Path $workspaceTempRoot "knowbase-release-preflight-smoke"
  Remove-TestDirectory $testRoot
  New-Item -ItemType Directory -Force -Path $testRoot | Out-Null

  try {
    $installerPath = Join-Path $testRoot "KnowBase_0.1.0_x64-setup.exe"
    Set-Content -LiteralPath $installerPath -Value "fake installer for release artifact preflight smoke test" -Encoding ASCII

    $zipPath = Join-Path $testRoot "KnowBaseDesktop-Windows-smoke.zip"
    Compress-Archive -LiteralPath $installerPath -DestinationPath $zipPath -Force

    $packageOutputDir = Join-Path $testRoot "prepared"
    New-Item -ItemType Directory -Force -Path $packageOutputDir | Out-Null
    $staleInstallerPath = Join-Path $packageOutputDir "KnowBase_0.0.0_x64-setup.exe"
    Set-Content -LiteralPath $staleInstallerPath -Value "stale installer" -Encoding ASCII
    & (Join-Path $PSScriptRoot "prepare-release-package.ps1") -ZipPath $zipPath -OutputDir $packageOutputDir -Version "0.1.0-smoke" -MinInstallerBytes 1 -AllowUnsigned
    if (-not $?) {
      exit 1
    }
    if (Test-Path -LiteralPath $staleInstallerPath) {
      Fail "Release package smoke check retained a stale installer: $staleInstallerPath"
    }

    $supportToolsZipPath = Join-Path $packageOutputDir "KnowBaseSupportTools.zip"
    $checksumPath = Join-Path $packageOutputDir "SHA256SUMS.txt"
    $validationIssuePath = Join-Path $packageOutputDir "RELEASE_VALIDATION_ISSUE_DRAFT.md"
    foreach ($requiredPath in @($supportToolsZipPath, $checksumPath, $validationIssuePath)) {
      if (-not (Test-Path -LiteralPath $requiredPath)) {
        Fail "Release package smoke check did not generate: $requiredPath"
      }
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $supportArchive = [System.IO.Compression.ZipFile]::OpenRead($supportToolsZipPath)
    try {
      $entryNames = @(
        $supportArchive.Entries |
          Where-Object { $_.Name } |
          ForEach-Object { $_.FullName }
      )
      $expectedEntries = @(
        "backup-local-data.ps1",
        "check-installed-app.ps1",
        "collect-support-info.ps1",
        "remove-local-data.ps1",
        "restore-local-data.ps1",
        "README.txt"
      )
      $missingEntries = @($expectedEntries | Where-Object { $_ -notin $entryNames })
      $unexpectedEntries = @($entryNames | Where-Object { $_ -notin $expectedEntries })
      if ($missingEntries.Count -gt 0 -or $unexpectedEntries.Count -gt 0) {
        Fail "Support tools ZIP entries do not match. Missing: $($missingEntries -join ', '); unexpected: $($unexpectedEntries -join ', ')."
      }

      $readmeEntry = $supportArchive.GetEntry("README.txt")
      $reader = New-Object System.IO.StreamReader($readmeEntry.Open())
      try {
        $readme = $reader.ReadToEnd()
      }
      finally {
        $reader.Dispose()
      }
    }
    finally {
      $supportArchive.Dispose()
    }

    foreach ($requiredText in @(
      "Desktop\KnowBaseValidation",
      "ProductVersion, signature status, installed executable path, and backend process path when available."
    )) {
      if (-not $readme.Contains($requiredText)) {
        Fail "Support tools README is missing required text: $requiredText"
      }
    }

    $supportToolsHash = Get-FileHash -Algorithm SHA256 -LiteralPath $supportToolsZipPath
    $expectedChecksumLine = "$($supportToolsHash.Hash)  KnowBaseSupportTools.zip"
    if ($expectedChecksumLine -notin (Get-Content -LiteralPath $checksumPath)) {
      Fail "SHA256SUMS.txt does not contain the generated support tools ZIP checksum."
    }

    $validationIssue = Get-Content -LiteralPath $validationIssuePath -Raw
    foreach ($requiredText in @(
      "## Signature Policy Decision",
      "Valid signature verified",
      "Unsigned build explicitly approved and disclosed",
      "Signature invalid or undecided - block release",
      "Thumbprint:",
      "Unsigned approver:",
      "Approval date:",
      "Release-notes disclosure:"
    )) {
      if (-not $validationIssue.Contains($requiredText)) {
        Fail "Release validation issue draft is missing required text: $requiredText"
      }
    }

    Write-Output "Release package support tools and validation draft smoke check passed."
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
Run-Check "Tauri security" (Join-Path $PSScriptRoot "check-tauri-security.ps1")
Run-Check "Desktop windowing" (Join-Path $PSScriptRoot "check-desktop-windowing.ps1")
Run-Check "Desktop icon" (Join-Path $PSScriptRoot "check-desktop-icon.ps1")
Run-Check "Frontend dialogs" (Join-Path $PSScriptRoot "check-frontend-dialogs.ps1")
Run-Check "Frontend localized text" (Join-Path $PSScriptRoot "check-frontend-text.ps1")
Run-Check "Complete bilingual localization" (Join-Path $PSScriptRoot "check-i18n-coverage.ps1")
Run-Check "Frontend API empty responses" (Join-Path $PSScriptRoot "check-frontend-api-empty-response.ps1")
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
