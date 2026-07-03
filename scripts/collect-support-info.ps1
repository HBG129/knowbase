param(
  [string]$OutputDir = "",
  [string]$HealthUrl = "http://127.0.0.1:8000/api/health"
)

$ErrorActionPreference = "Stop"

function Redact-Path($Path) {
  if (-not $Path) {
    return ""
  }

  $value = [string]$Path
  if ($env:USERPROFILE) {
    $value = $value.Replace($env:USERPROFILE, "%USERPROFILE%")
  }
  if ($env:APPDATA) {
    $value = $value.Replace($env:APPDATA, "%APPDATA%")
  }
  if ($env:LOCALAPPDATA) {
    $value = $value.Replace($env:LOCALAPPDATA, "%LOCALAPPDATA%")
  }

  return $value
}

function Add-Line($Line) {
  $script:report.Add($Line)
}

function Get-ShortcutTarget($Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    return $null
  }

  try {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Path)
    if ($shortcut.TargetPath) {
      return $shortcut.TargetPath
    }
  } catch {
    return $null
  }

  return $null
}

if (-not $OutputDir) {
  $desktop = [Environment]::GetFolderPath("Desktop")
  if ($desktop) {
    $OutputDir = Join-Path $desktop "KnowBaseSupport"
  } else {
    $OutputDir = Join-Path $env:TEMP "KnowBaseSupport"
  }
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = Join-Path $OutputDir "knowbase-support-info-$timestamp.md"
$report = New-Object System.Collections.Generic.List[string]

$appDataDir = Join-Path $env:APPDATA "KnowBase"
$candidateExePaths = @(
  (Join-Path $env:LOCALAPPDATA "Programs\KnowBase\KnowBase.exe"),
  (Join-Path $env:ProgramFiles "KnowBase\KnowBase.exe"),
  (Join-Path ${env:ProgramFiles(x86)} "KnowBase\KnowBase.exe")
) | Where-Object { $_ -and $_.Trim() }

$candidateShortcutPaths = @(
  (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\KnowBase.lnk"),
  (Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\KnowBase.lnk"),
  (Join-Path ([Environment]::GetFolderPath("Desktop")) "KnowBase.lnk")
) | Where-Object { $_ -and $_.Trim() }

$shortcutTargets = @(
  $candidateShortcutPaths | ForEach-Object { Get-ShortcutTarget $_ }
) | Where-Object { $_ -and $_.Trim() }

$candidateExePaths = @(
  $candidateExePaths
  $shortcutTargets
) | Select-Object -Unique

$existingExe = @($candidateExePaths | Where-Object { Test-Path -LiteralPath $_ })
$existingShortcuts = @($candidateShortcutPaths | Where-Object { Test-Path -LiteralPath $_ })
$knowBaseProcesses = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -ieq "knowbase" })
$backendProcesses = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -eq "KnowBaseBackend" })

Add-Line "# KnowBase Support Info"
Add-Line ""
Add-Line "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
Add-Line ""
Add-Line "This report is intended for support triage. It does not collect API keys, database contents, uploaded document contents, or uploaded file names."
Add-Line ""
Add-Line "## System"
Add-Line ""
Add-Line "- Windows version: $([Environment]::OSVersion.VersionString)"
Add-Line "- PowerShell version: $($PSVersionTable.PSVersion)"
Add-Line "- Machine architecture: $env:PROCESSOR_ARCHITECTURE"
Add-Line ""
Add-Line "## Installation"
Add-Line ""
Add-Line "- Known executable found: $($existingExe.Count -gt 0)"
foreach ($path in $existingExe) {
  Add-Line "  - $(Redact-Path $path)"
}
Add-Line "- Known shortcut found: $($existingShortcuts.Count -gt 0)"
foreach ($path in $existingShortcuts) {
  Add-Line "  - $(Redact-Path $path)"
}
Add-Line ""
Add-Line "## Runtime"
Add-Line ""
Add-Line "- KnowBase process count: $($knowBaseProcesses.Count)"
Add-Line "- KnowBaseBackend process count: $($backendProcesses.Count)"
Add-Line "- Health URL checked: ``$HealthUrl``"

try {
  $health = Invoke-RestMethod -Uri $HealthUrl -TimeoutSec 5
  $healthText = $health | ConvertTo-Json -Compress
  Add-Line "- Health endpoint result: ``$healthText``"
} catch {
  Add-Line "- Health endpoint result: failed - $($_.Exception.Message)"
}

Add-Line ""
Add-Line "## Local Data Presence"
Add-Line ""
Add-Line "- Expected data directory exists: $(Test-Path -LiteralPath $appDataDir)"
Add-Line "- Expected data directory: ``$(Redact-Path $appDataDir)``"
Add-Line "- Database file exists: $(Test-Path -LiteralPath (Join-Path $appDataDir "knowbase.db"))"
Add-Line "- Uploads directory exists: $(Test-Path -LiteralPath (Join-Path $appDataDir "uploads"))"
Add-Line ""
Add-Line "## Safe Sharing Reminder"
Add-Line ""
Add-Line "- Share this Markdown report only after checking it for private details."
Add-Line '- Do not attach API keys, `.env` files, databases, uploaded documents, or the full `%APPDATA%\KnowBase` folder.'

Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

Write-Output "Support info report written:"
Write-Output $reportPath
