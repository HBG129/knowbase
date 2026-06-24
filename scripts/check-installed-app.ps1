param(
  [string]$OutputDir = "",
  [string]$HealthUrl = "http://127.0.0.1:8000/api/health",
  [switch]$AllowFailures
)

$ErrorActionPreference = "Stop"

if (-not $OutputDir) {
  $desktop = [Environment]::GetFolderPath("Desktop")
  if ($desktop) {
    $OutputDir = Join-Path $desktop "KnowBaseValidation"
  } else {
    $OutputDir = Join-Path $env:TEMP "KnowBaseValidation"
  }
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = Join-Path $OutputDir "knowbase-installed-check-$timestamp.md"
$results = New-Object System.Collections.Generic.List[string]
$failedChecks = 0

function Add-Check($Name, $Passed, $Details) {
  $status = if ($Passed) { "PASS" } else { "FAIL" }
  if (-not $Passed) {
    $script:failedChecks += 1
  }
  $script:results.Add("- [$status] $Name - $Details")
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

$appDataDir = Join-Path $env:APPDATA "KnowBase"
$commonExePaths = @(
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
  $commonExePaths
  $shortcutTargets
) | Select-Object -Unique

$existingExe = @($candidateExePaths | Where-Object { Test-Path -LiteralPath $_ })
$existingShortcuts = @($candidateShortcutPaths | Where-Object { Test-Path -LiteralPath $_ })
$knowBaseProcesses = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "KnowBase*" })
$backendProcesses = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -eq "KnowBaseBackend" })
$healthUrlLine = "Health URL: ``$HealthUrl``"
$appDataDirLine = "Expected data directory: ``$appDataDir``"

Add-Check "Installed app executable" ($existingExe.Count -gt 0) ($(if ($existingExe.Count -gt 0) { $existingExe -join "; " } else { "No KnowBase.exe found in common install locations." }))
Add-Check "Shortcut" ($existingShortcuts.Count -gt 0) ($(if ($existingShortcuts.Count -gt 0) { $existingShortcuts -join "; " } else { "No Start Menu or Desktop shortcut found in common locations." }))
Add-Check "App data directory" (Test-Path -LiteralPath $appDataDir) $appDataDir
Add-Check "KnowBase process" ($knowBaseProcesses.Count -gt 0) ($(if ($knowBaseProcesses.Count -gt 0) { ($knowBaseProcesses | Select-Object -ExpandProperty Id) -join ", " } else { "No KnowBase process is currently running." }))
Add-Check "Backend process" ($backendProcesses.Count -gt 0) ($(if ($backendProcesses.Count -gt 0) { ($backendProcesses | Select-Object -ExpandProperty Id) -join ", " } else { "No KnowBaseBackend process is currently running." }))

try {
  $health = Invoke-RestMethod -Uri $HealthUrl -TimeoutSec 5
  $healthText = $health | ConvertTo-Json -Compress
  Add-Check "Backend health endpoint" ($healthText -match '"status":"ok"') "$HealthUrl returned $healthText"
} catch {
  Add-Check "Backend health endpoint" $false "$HealthUrl failed: $($_.Exception.Message)"
}

$report = @(
  "# KnowBase Installed App Check"
  ""
  "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
  ""
  $healthUrlLine
  $appDataDirLine
  ""
  "## Checks"
  ""
  $results
  ""
  "## Notes"
  ""
  "- Run this after installing and launching KnowBase on a clean Windows machine."
  "- This script is read-only except for writing this report."
  '- Do not attach API keys, private documents, databases, or `%APPDATA%\KnowBase` contents to GitHub issues.'
)

Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

Write-Output "Installed app check report written:"
Write-Output $reportPath
Write-Output ""
$results | ForEach-Object { Write-Output $_ }

if ($failedChecks -gt 0 -and -not $AllowFailures) {
  Write-Error "Installed app check failed: $failedChecks check(s) failed. Report: $reportPath"
  exit 1
}
