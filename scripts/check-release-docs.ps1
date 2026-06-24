$ErrorActionPreference = "Stop"

function Fail($Messages) {
  foreach ($message in $Messages) {
    Write-Error $message
  }
  exit 1
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$errors = New-Object System.Collections.Generic.List[string]
$issueTemplates = @(
  ".github\ISSUE_TEMPLATE\beta_feedback.yml",
  ".github\ISSUE_TEMPLATE\bug_report.yml",
  ".github\ISSUE_TEMPLATE\feature_request.yml",
  ".github\ISSUE_TEMPLATE\release_validation.yml"
)

$requiredPaths = @(
  "README.md",
  "SECURITY.md",
  "check-desktop-prereqs.bat",
  "package-desktop.bat",
  ".github\workflows\ci.yml",
  ".github\workflows\desktop-package.yml",
  ".github\ISSUE_TEMPLATE\beta_feedback.yml",
  ".github\ISSUE_TEMPLATE\release_validation.yml",
  "docs\README.md",
  "docs\clean-machine-validation.md",
  "docs\customer-data-and-privacy.md",
  "docs\customer-beta-test-plan.md",
  "docs\customer-quick-start.md",
  "docs\customer-troubleshooting.md",
  "docs\demo-assets.md",
  "docs\demo-data",
  "docs\known-limitations.md",
  "docs\privacy-notice-draft.md",
  "docs\release-notes-template.md",
  "docs\release-process.md",
  "docs\release-readiness-checklist.md",
  "docs\support-runbook.md",
  "backend\app\config.py",
  "frontend\next.config.js",
  "frontend\src-tauri\src\backend_runtime.rs",
  "frontend\src-tauri\tauri.conf.json",
  "scripts\backup-local-data.ps1",
  "scripts\check-desktop-artifacts.ps1",
  "scripts\check-code-signature.ps1",
  "scripts\check-frontend-dialogs.ps1",
  "scripts\check-frontend-text.ps1",
  "scripts\check-installed-app.ps1",
  "scripts\check-installer-hooks.ps1",
  "scripts\check-powershell-scripts.ps1",
  "scripts\check-release-artifact.ps1",
  "scripts\check-release-docs.ps1",
  "scripts\check-release-preflight.ps1",
  "scripts\check-sensitive-files.ps1",
  "scripts\check-version-consistency.ps1",
  "scripts\collect-support-info.ps1",
  "scripts\remove-local-data.ps1",
  "scripts\restore-local-data.ps1",
  "scripts\prepare-release-package.ps1"
)

foreach ($path in $requiredPaths) {
  $fullPath = Join-Path $repoRoot $path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    $errors.Add("Missing required release path: $path")
  }
}

$contentChecks = @(
  @{
    Path = "README.md"
    Needle = "docs\customer-quick-start.md"
  },
  @{
    Path = "README.md"
    Needle = "docs\customer-data-and-privacy.md"
  },
  @{
    Path = "docs\README.md"
    Needle = "customer-troubleshooting.md"
  },
  @{
    Path = "docs\README.md"
    Needle = "customer-beta-test-plan.md"
  },
  @{
    Path = "docs\README.md"
    Needle = "privacy-notice-draft.md"
  },
  @{
    Path = "docs\customer-beta-test-plan.md"
    Needle = "docs\privacy-notice-draft.md"
  },
  @{
    Path = "docs\release-readiness-checklist.md"
    Needle = "docs\privacy-notice-draft.md"
  },
  @{
    Path = "docs\roadmap.md"
    Needle = "docs\customer-beta-test-plan.md"
  },
  @{
    Path = "docs\release-readiness-checklist.md"
    Needle = "docs\customer-beta-test-plan.md"
  },
  @{
    Path = "docs\customer-beta-test-plan.md"
    Needle = "Beta feedback"
  },
  @{
    Path = "docs\customer-quick-start.md"
    Needle = "docs\customer-troubleshooting.md"
  },
  @{
    Path = "docs\clean-machine-validation.md"
    Needle = ".\scripts\collect-support-info.ps1"
  },
  @{
    Path = "docs\clean-machine-validation.md"
    Needle = "docs\customer-troubleshooting.md"
  },
  @{
    Path = "docs\clean-machine-validation.md"
    Needle = "KnowBaseDesktop-Windows-<run number>.zip"
  },
  @{
    Path = "docs\clean-machine-validation.md"
    Needle = "Installing or uninstalling while KnowBase is still running"
  },
  @{
    Path = "docs\release-process.md"
    Needle = ".\scripts\check-release-preflight.ps1"
  },
  @{
    Path = "docs\release-process.md"
    Needle = ".\scripts\prepare-release-package.ps1"
  },
  @{
    Path = "docs\release-process.md"
    Needle = ".\scripts\check-code-signature.ps1"
  },
  @{
    Path = "docs\release-readiness-checklist.md"
    Needle = ".\scripts\check-release-preflight.ps1"
  },
  @{
    Path = "docs\release-readiness-checklist.md"
    Needle = ".\scripts\check-code-signature.ps1"
  },
  @{
    Path = "docs\release-readiness-checklist.md"
    Needle = "Backup and restore scripts"
  },
  @{
    Path = "docs\release-readiness-checklist.md"
    Needle = "docs\clean-machine-validation.md"
  },
  @{
    Path = "frontend\next.config.js"
    Needle = 'output: "export"'
  },
  @{
    Path = "frontend\next.config.js"
    Needle = "trailingSlash: true"
  },
  @{
    Path = "backend\app\config.py"
    Needle = "tauri://localhost"
  },
  @{
    Path = "frontend\src-tauri\src\backend_runtime.rs"
    Needle = "CORS_ORIGINS"
  },
  @{
    Path = "frontend\src-tauri\tauri.conf.json"
    Needle = '"frontendDist": "../out"'
  },
  @{
    Path = "frontend\src-tauri\tauri.conf.json"
    Needle = '"installerHooks": "nsis/installer-hooks.nsh"'
  },
  @{
    Path = ".github\PULL_REQUEST_TEMPLATE.md"
    Needle = ".\scripts\check-release-preflight.ps1 -SkipGitStatus"
  },
  @{
    Path = "docs\support-runbook.md"
    Needle = ".\scripts\collect-support-info.ps1"
  },
  @{
    Path = "docs\customer-data-and-privacy.md"
    Needle = ".\scripts\backup-local-data.ps1"
  },
  @{
    Path = "docs\customer-data-and-privacy.md"
    Needle = ".\scripts\remove-local-data.ps1"
  },
  @{
    Path = "docs\customer-data-and-privacy.md"
    Needle = ".\scripts\restore-local-data.ps1"
  },
  @{
    Path = "docs\release-notes-template.md"
    Needle = "Local data backup dry-run"
  },
  @{
    Path = "docs\release-notes-template.md"
    Needle = "Local data restore dry-run"
  },
  @{
    Path = "docs\release-notes-template.md"
    Needle = "Local data removal dry-run"
  },
  @{
    Path = ".github\ISSUE_TEMPLATE\bug_report.yml"
    Needle = ".\scripts\collect-support-info.ps1"
  },
  @{
    Path = ".github\ISSUE_TEMPLATE\release_validation.yml"
    Needle = "collect-support-info.ps1"
  },
  @{
    Path = ".github\ISSUE_TEMPLATE\release_validation.yml"
    Needle = "Local data backup dry-run"
  },
  @{
    Path = ".github\ISSUE_TEMPLATE\release_validation.yml"
    Needle = "Local data restore dry-run"
  },
  @{
    Path = ".github\ISSUE_TEMPLATE\release_validation.yml"
    Needle = "Local data removal dry-run"
  }
)

$forbiddenContentChecks = @(
  @{
    Path = "docs\clean-machine-validation.md"
    Needle = "KnowBaseDesktop-Windows-3.zip"
  },
  @{
    Path = "docs\clean-machine-validation.md"
    Needle = "552E81842025B52D0B9C106257D2B2D08E69CA52BCD9169DF5F87A31F699FB26"
  }
)

foreach ($check in $contentChecks) {
  $fullPath = Join-Path $repoRoot $check.Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    $errors.Add("Cannot check missing file: $($check.Path)")
    continue
  }

  $content = Get-Content -LiteralPath $fullPath -Raw
  if (-not $content.Contains($check.Needle)) {
    $errors.Add("$($check.Path) does not mention required text: $($check.Needle)")
  }
}

foreach ($check in $forbiddenContentChecks) {
  $fullPath = Join-Path $repoRoot $check.Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    $errors.Add("Cannot check missing file: $($check.Path)")
    continue
  }

  $content = Get-Content -LiteralPath $fullPath -Raw
  if ($content.Contains($check.Needle)) {
    $errors.Add("$($check.Path) contains stale release text: $($check.Needle)")
  }
}

foreach ($path in $issueTemplates) {
  $fullPath = Join-Path $repoRoot $path
  $lineNumber = 0
  foreach ($line in Get-Content -LiteralPath $fullPath) {
    $lineNumber += 1
    if ($line -match '^\s*placeholder:\s+[^"''|].*:\s+') {
      $errors.Add("Issue template placeholder with colon must be quoted: $path line $lineNumber")
    }
  }
}

if ($errors.Count -gt 0) {
  Fail $errors
}

Write-Output "Release documentation check passed."
