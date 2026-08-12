param(
  [Parameter(Mandatory = $true)]
  [string]$CertificateThumbprint,

  [Parameter(Mandatory = $true)]
  [string]$TimestampUrl
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$frontendRoot = Join-Path $repoRoot "frontend"
$backendRoot = Join-Path $repoRoot "backend"
$tauriRoot = Join-Path $frontendRoot "src-tauri"
$backendExe = Join-Path $repoRoot "backend\dist\KnowBaseBackend.exe"
$mainExe = Join-Path $tauriRoot "target\release\knowbase.exe"
$nsisDir = Join-Path $tauriRoot "target\release\bundle\nsis"
$tempRoot = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { Join-Path (Split-Path -Parent $repoRoot) ".tmp" }
$configPath = Join-Path $tempRoot "knowbase-signed-tauri-$([guid]::NewGuid().ToString('N')).json"
$CertificateThumbprint = ($CertificateThumbprint -replace "\s", "").ToUpperInvariant()

function Fail($Message) {
  Write-Error $Message
  exit 1
}

function Import-MsvcEnvironment {
  if ((Get-Command "cl.exe" -ErrorAction SilentlyContinue) -and
      (Get-Command "link.exe" -ErrorAction SilentlyContinue)) {
    return
  }

  $vsDevCmd = $null
  $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
  if (Test-Path -LiteralPath $vswhere) {
    $installationPath = & $vswhere -latest -products * `
      -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($installationPath) {
      $candidate = Join-Path $installationPath "Common7\Tools\VsDevCmd.bat"
      if (Test-Path -LiteralPath $candidate) { $vsDevCmd = $candidate }
    }
  }

  if (-not $vsDevCmd) {
    $candidates = @(
      (Join-Path $env:ProgramFiles "Microsoft Visual Studio\2026\Enterprise\Common7\Tools\VsDevCmd.bat"),
      (Join-Path $env:ProgramFiles "Microsoft Visual Studio\2026\BuildTools\Common7\Tools\VsDevCmd.bat"),
      (Join-Path $env:ProgramFiles "Microsoft Visual Studio\2026\Community\Common7\Tools\VsDevCmd.bat"),
      (Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"),
      (Join-Path $env:ProgramFiles "Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"),
      (Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"),
      (Join-Path $env:ProgramFiles "Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat")
    )
    $vsDevCmd = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
  }

  if (-not $vsDevCmd) {
    Fail "Visual Studio developer environment was not found."
  }

  $environmentLines = & cmd.exe /d /s /c "`"$vsDevCmd`" -arch=x64 -host_arch=x64 >nul && set"
  if ($LASTEXITCODE -ne 0) {
    Fail "Visual Studio developer environment could not be loaded."
  }
  foreach ($line in $environmentLines) {
    $separator = $line.IndexOf("=")
    if ($separator -gt 0) {
      [Environment]::SetEnvironmentVariable($line.Substring(0, $separator), $line.Substring($separator + 1), "Process")
    }
  }

  if (-not (Get-Command "cl.exe" -ErrorAction SilentlyContinue) -or
      -not (Get-Command "link.exe" -ErrorAction SilentlyContinue)) {
    Fail "Visual Studio developer environment did not expose cl.exe and link.exe."
  }
}

function Sync-LockedBackendEnvironment {
  $uvCommand = Get-Command "uv" -ErrorAction SilentlyContinue
  $uvPath = if ($uvCommand) { $uvCommand.Source } else { Join-Path $backendRoot ".venv\Scripts\uv.exe" }
  if (-not (Test-Path -LiteralPath $uvPath -PathType Leaf)) {
    Fail "uv was not found. Install uv 0.11.32 before building a signed release."
  }
  $pythonPath = Join-Path $backendRoot ".venv\Scripts\python.exe"
  if (-not (Test-Path -LiteralPath $pythonPath -PathType Leaf)) {
    Fail "Backend virtual environment was not found: $pythonPath"
  }

  $syncUvPath = $uvPath
  $copiedUvPath = ""
  if ([System.IO.Path]::GetFullPath($uvPath).StartsWith(
      [System.IO.Path]::GetFullPath((Join-Path $backendRoot ".venv")),
      [System.StringComparison]::OrdinalIgnoreCase)) {
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    $copiedUvPath = Join-Path $tempRoot "knowbase-uv-$([guid]::NewGuid().ToString('N')).exe"
    Copy-Item -LiteralPath $uvPath -Destination $copiedUvPath -Force
    $syncUvPath = $copiedUvPath
  }

  try {
    & $syncUvPath sync --project $backendRoot --locked --extra dev --extra packaging --no-install-project `
      --python $pythonPath
    if ($LASTEXITCODE -ne 0) { Fail "Locked backend dependency sync failed." }
  }
  finally {
    if ($copiedUvPath -and (Test-Path -LiteralPath $copiedUvPath)) {
      Remove-Item -LiteralPath $copiedUvPath -Force
    }
  }
}

& (Join-Path $PSScriptRoot "check-signing-certificate.ps1") `
  -CertificateThumbprint $CertificateThumbprint
if (-not $?) { exit 1 }

& (Join-Path $repoRoot "check-desktop-prereqs.bat")
if ($LASTEXITCODE -ne 0) { Fail "Desktop prerequisites check failed." }
Import-MsvcEnvironment
Sync-LockedBackendEnvironment

& (Join-Path $PSScriptRoot "prepare-webview2-fixed-runtime.ps1")
if (-not $?) { exit 1 }

& (Join-Path $repoRoot "package-backend.bat")
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $backendExe -PathType Leaf)) {
  Fail "Backend packaging failed."
}

& (Join-Path $PSScriptRoot "sign-windows-artifact.ps1") -Path $backendExe `
  -CertificateThumbprint $CertificateThumbprint -TimestampUrl $TimestampUrl
if (-not $?) { exit 1 }

$signingConfig = @{
  bundle = @{
    windows = @{
      "certificateThumbprint" = $CertificateThumbprint
      "digestAlgorithm" = "sha256"
      "timestampUrl" = $TimestampUrl
    }
  }
}
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
$signingConfig | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $configPath -Encoding UTF8

try {
  Push-Location $frontendRoot
  try {
    & npm run tauri:build -- --config $configPath
    if ($LASTEXITCODE -ne 0) { Fail "Signed Tauri build failed." }
  }
  finally {
    Pop-Location
  }
}
finally {
  if (Test-Path -LiteralPath $configPath) {
    Remove-Item -LiteralPath $configPath -Force
  }
}

$installer = Get-ChildItem -LiteralPath $nsisDir -Filter "*.exe" -File -ErrorAction SilentlyContinue |
  Select-Object -First 1
if (-not $installer) { Fail "Signed NSIS installer was not created." }

foreach ($artifact in @($backendExe, $mainExe, $installer.FullName)) {
  & (Join-Path $PSScriptRoot "check-code-signature.ps1") -Path $artifact `
    -ExpectedThumbprint $CertificateThumbprint -RequireTimestamp
  if (-not $?) { exit 1 }
}

Write-Output "Signed desktop release build passed."
Write-Output "Backend: $backendExe"
Write-Output "Desktop executable: $mainExe"
Write-Output "Installer: $($installer.FullName)"
