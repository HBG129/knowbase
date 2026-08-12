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
  "AGENTS.md",
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
  "docs\release-candidate-v0.1.0-rc.1.md",
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
  "scripts\check-signing-certificate.ps1",
  "scripts\sign-windows-artifact.ps1",
  "scripts\build-signed-release.ps1",
  "scripts\check-frontend-api-empty-response.ps1",
  "scripts\check-frontend-dialogs.ps1",
  "scripts\check-frontend-text.ps1",
  "scripts\check-installed-app.ps1",
  "scripts\check-installer-hooks.ps1",
  "scripts\check-packaged-backend-health.ps1",
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
    Path = "AGENTS.md"
    Needle = "CSV Analysis Agent"
  },
  @{
    Path = "AGENTS.md"
    Needle = "Release target"
  },
  @{
    Path = "AGENTS.md"
    Needle = "Required Verification Gates"
  },
  @{
    Path = "AGENTS.md"
    Needle = "npm audit --omit=dev --audit-level=high"
  },
  @{
    Path = "AGENTS.md"
    Needle = "Frontend production dependency audit is release-clean"
  },
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
    Needle = "..\AGENTS.md"
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
    Path = "docs\README.md"
    Needle = "release-candidate-v0.1.0-rc.1.md"
  },
  @{
    Path = "docs\release-candidate-v0.1.0-rc.1.md"
    Needle = 'Controlled tester candidate: `v0.1.0-rc.1`'
  },
  @{
    Path = "docs\release-candidate-v0.1.0-rc.1.md"
    Needle = "Do not create a public GitHub Release"
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
    Path = "docs\architecture.md"
    Needle = "CSV Analysis"
  },
  @{
    Path = "docs\architecture.md"
    Needle = "read-only SELECT or WITH query"
  },
  @{
    Path = "docs\project-status.md"
    Needle = "Backend test suite passes locally."
  },
  @{
    Path = "docs\project-status.md"
    Needle = "Frontend production dependency audit is release-clean"
  },
  @{
    Path = "docs\project-status.md"
    Needle = "CSV Analysis Agent is implemented"
  },
  @{
    Path = "docs\roadmap.md"
    Needle = "CSV Analysis Agent"
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
    Needle = "collect-support-info.ps1"
  },
  @{
    Path = "docs\clean-machine-validation.md"
    Needle = "KnowBaseSupportTools.zip"
  },
  @{
    Path = "docs\clean-machine-validation.md"
    Needle = "powershell -ExecutionPolicy Bypass -File .\check-installed-app.ps1"
  },
  @{
    Path = "scripts\prepare-release-package.ps1"
    Needle = "KnowBaseSupportTools.zip"
  },
  @{
    Path = "scripts\prepare-release-package.ps1"
    Needle = "support-tools"
  },
  @{
    Path = "scripts\prepare-release-package.ps1"
    Needle = "Desktop\KnowBaseValidation"
  },
  @{
    Path = "scripts\prepare-release-package.ps1"
    Needle = "ProductVersion, signature status, installed executable path, and backend process path when available."
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
    Needle = "explicitly approved unsigned validation or release builds"
  },
  @{
    Path = "docs\release-process.md"
    Needle = "record the signer or the unsigned approver, approval date, and exact release-notes disclosure"
  },
  @{
    Path = "docs\release-process.md"
    Needle = ".\scripts\check-code-signature.ps1"
  },
  @{
    Path = "docs\release-process.md"
    Needle = ".\scripts\check-packaged-backend-health.ps1"
  },
  @{
    Path = "docs\release-process.md"
    Needle = "Signed Windows Release Candidate"
  },
  @{
    Path = "docs\release-process.md"
    Needle = "WINDOWS_CERTIFICATE_BASE64"
  },
  @{
    Path = "docs\release-process.md"
    Needle = "release-signing"
  },
  @{
    Path = ".github\workflows\signed-release.yml"
    Needle = "environment: release-signing"
  },
  @{
    Path = ".github\workflows\signed-release.yml"
    Needle = "build-signed-release.ps1"
  },
  @{
    Path = "docs\release-process.md"
    Needle = 'Extract `KnowBaseSupportTools.zip` into a folder named `support-tools`.'
  },
  @{
    Path = "docs\release-process.md"
    Needle = "cd .\support-tools"
  },
  @{
    Path = "docs\release-process.md"
    Needle = "powershell -ExecutionPolicy Bypass -File .\check-installed-app.ps1"
  },
  @{
    Path = "README.md"
    Needle = ".\scripts\check-packaged-backend-health.ps1"
  },
  @{
    Path = "docs\release-readiness-checklist.md"
    Needle = "run CSV analysis"
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
    Needle = ".\scripts\check-packaged-backend-health.ps1"
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
    Path = "frontend\src-tauri\tauri.conf.json"
    Needle = '"type": "fixedRuntime"'
  },
  @{
    Path = "frontend\src-tauri\tauri.conf.json"
    Needle = '"path": "./WebView2.FixedVersionRuntime.x64"'
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
    Path = "docs\customer-data-and-privacy.md"
    Needle = "CSV data analysis"
  },
  @{
    Path = "docs\customer-quick-start.md"
    Needle = "Analysis tab"
  },
  @{
    Path = "docs\clean-machine-validation.md"
    Needle = "signature status"
  },
  @{
    Path = "docs\support-runbook.md"
    Needle = "check-installed-app.ps1"
  },
  @{
    Path = "scripts\check-installed-app.ps1"
    Needle = "## Build Identity"
  },
  @{
    Path = "scripts\check-installed-app.ps1"
    Needle = "Backend process path"
  },
  @{
    Path = "docs\clean-machine-validation.md"
    Needle = "CSV Analysis tab"
  },
  @{
    Path = "docs\clean-machine-validation.md"
    Needle = "Manual WebView2 Runtime installation"
  },
  @{
    Path = "docs\release-readiness-checklist.md"
    Needle = "CSV Analysis tab"
  },
  @{
    Path = ".github\ISSUE_TEMPLATE\release_validation.yml"
    Needle = "CSV Analysis tab"
  },
  @{
    Path = ".github\ISSUE_TEMPLATE\release_validation.yml"
    Needle = "UI renders without a separate WebView2 Runtime download or installation."
  },
  @{
    Path = ".github\ISSUE_TEMPLATE\release_validation.yml"
    Needle = "id: signature_policy"
  },
  @{
    Path = ".github\ISSUE_TEMPLATE\release_validation.yml"
    Needle = "id: signature_evidence"
  },
  @{
    Path = ".github\ISSUE_TEMPLATE\release_validation.yml"
    Needle = "A Ready decision is selected only when every required validation check above is complete; otherwise the release decision is Block release and failures are documented."
  },
  @{
    Path = ".github\ISSUE_TEMPLATE\release_validation.yml"
    Needle = "Unsigned approver, approval date, and exact release-notes disclosure"
  },
  @{
    Path = "scripts\prepare-release-package.ps1"
    Needle = "## Signature Policy Decision"
  },
  @{
    Path = "docs\known-limitations.md"
    Needle = "CSV data analysis"
  },
  @{
    Path = "scripts\prepare-release-package.ps1"
    Needle = "CSV data analysis in Analysis tab"
  },
  @{
    Path = "scripts\prepare-release-package.ps1"
    Needle = "CSV Analysis tab preview, query, chart, summary, and history work."
  },
  @{
    Path = "docs\release-notes-template.md"
    Needle = "CSV data analysis in Analysis tab"
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
