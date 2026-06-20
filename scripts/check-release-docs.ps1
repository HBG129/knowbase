$ErrorActionPreference = "Stop"

function Fail($Messages) {
  foreach ($message in $Messages) {
    Write-Error $message
  }
  exit 1
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$errors = New-Object System.Collections.Generic.List[string]

$requiredPaths = @(
  "README.md",
  "SECURITY.md",
  "check-desktop-prereqs.bat",
  "package-desktop.bat",
  ".github\workflows\ci.yml",
  ".github\workflows\desktop-package.yml",
  ".github\ISSUE_TEMPLATE\release_validation.yml",
  "docs\README.md",
  "docs\clean-machine-validation.md",
  "docs\customer-data-and-privacy.md",
  "docs\customer-quick-start.md",
  "docs\demo-assets.md",
  "docs\demo-data",
  "docs\known-limitations.md",
  "docs\release-notes-template.md",
  "docs\release-process.md",
  "docs\release-readiness-checklist.md",
  "docs\support-runbook.md",
  "scripts\check-desktop-artifacts.ps1",
  "scripts\check-installed-app.ps1",
  "scripts\check-powershell-scripts.ps1",
  "scripts\check-release-artifact.ps1",
  "scripts\check-release-docs.ps1",
  "scripts\check-release-preflight.ps1",
  "scripts\check-sensitive-files.ps1",
  "scripts\check-version-consistency.ps1",
  "scripts\collect-support-info.ps1",
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
    Path = "docs\release-process.md"
    Needle = ".\scripts\check-release-preflight.ps1"
  },
  @{
    Path = "docs\release-process.md"
    Needle = ".\scripts\prepare-release-package.ps1"
  },
  @{
    Path = "docs\release-readiness-checklist.md"
    Needle = ".\scripts\check-release-preflight.ps1"
  },
  @{
    Path = "docs\release-readiness-checklist.md"
    Needle = "docs\clean-machine-validation.md"
  },
  @{
    Path = ".github\PULL_REQUEST_TEMPLATE.md"
    Needle = ".\scripts\check-release-preflight.ps1 -SkipGitStatus"
  },
  @{
    Path = "docs\support-runbook.md"
    Needle = ".\scripts\collect-support-info.ps1"
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

if ($errors.Count -gt 0) {
  Fail $errors
}

Write-Output "Release documentation check passed."
