param(
  [string]$Root = "",
  [int]$Port = 8765,
  [int]$TimeoutSeconds = 30,
  [string]$DataDir = ""
)

$ErrorActionPreference = "Stop"

if (-not $Root) {
  $Root = Split-Path -Parent $PSScriptRoot
}

$repoRoot = Resolve-Path -LiteralPath $Root
$backendExe = Join-Path $repoRoot.Path "backend\dist\KnowBaseBackend.exe"
if (-not (Test-Path -LiteralPath $backendExe -PathType Leaf)) {
  throw "Missing packaged backend executable: $backendExe"
}

$workspaceTempRoot = Join-Path (Split-Path -Parent $repoRoot.Path) ".tmp"
$usingDefaultDataDir = $false
if (-not $DataDir) {
  $DataDir = Join-Path $workspaceTempRoot "knowbase-packaged-backend-health"
  $usingDefaultDataDir = $true
}
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null

$existingIds = @(
  Get-Process -Name KnowBaseBackend -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Id
)

$previousPort = $env:KNOWBASE_BACKEND_PORT
$previousDataDir = $env:KNOWBASE_DATA_DIR
$process = $null
$logSuffix = "$PID-$Port"
$stdoutPath = Join-Path $workspaceTempRoot "knowbase-packaged-backend-$logSuffix.stdout.log"
$stderrPath = Join-Path $workspaceTempRoot "knowbase-packaged-backend-$logSuffix.stderr.log"

try {
  $env:KNOWBASE_BACKEND_PORT = [string]$Port
  $env:KNOWBASE_DATA_DIR = $DataDir

  $process = Start-Process -FilePath $backendExe -PassThru -WindowStyle Hidden `
    -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  $healthUrl = "http://127.0.0.1:$Port/api/health"
  $healthy = $false

  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 500
    try {
      $response = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 2
      if ($response.status -eq "ok") {
        $healthy = $true
        break
      }
    } catch {
      if ($process.HasExited) {
        break
      }
    }
  }

  if (-not $healthy) {
    if (-not $process.HasExited) {
      Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
      $process.WaitForExit()
    }
    $exitCode = if ($process.HasExited) { $process.ExitCode } else { "unknown" }
    $stdout = if (Test-Path -LiteralPath $stdoutPath) { Get-Content -LiteralPath $stdoutPath -Raw } else { "<none>" }
    $stderr = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw } else { "<none>" }
    throw "Packaged backend health check failed on port $Port with exit code $exitCode.`nPackaged backend stdout:`n$stdout`nPackaged backend stderr:`n$stderr"
  }

  $openApiUrl = "http://127.0.0.1:$Port/openapi.json"
  $openApi = Invoke-RestMethod -Uri $openApiUrl -TimeoutSec 5
  $requiredAnalysisPaths = @(
    "/api/kb/{kb_id}/analysis/datasets",
    "/api/kb/{kb_id}/analysis/query",
    "/api/kb/{kb_id}/analysis/runs"
  )
  $availablePaths = @($openApi.paths.PSObject.Properties.Name)
  $missingAnalysisPaths = @($requiredAnalysisPaths | Where-Object { $_ -notin $availablePaths })
  if ($missingAnalysisPaths.Count -gt 0) {
    throw "Packaged backend OpenAPI is missing Analysis routes: $($missingAnalysisPaths -join ', ')."
  }

  $requiredAnalysisSchemas = @("AnalysisDatasetResponse", "AnalysisRunResponse")
  $availableSchemas = @($openApi.components.schemas.PSObject.Properties.Name)
  $missingAnalysisSchemas = @($requiredAnalysisSchemas | Where-Object { $_ -notin $availableSchemas })
  if ($missingAnalysisSchemas.Count -gt 0) {
    throw "Packaged backend OpenAPI is missing Analysis schemas: $($missingAnalysisSchemas -join ', ')."
  }

  Write-Output "Packaged backend health check passed on port $Port."
  Write-Output "Packaged backend Analysis API contract check passed."
} finally {
  if ($null -ne $process -and -not $process.HasExited) {
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
  }

  $currentProcesses = @(
    Get-Process -Name KnowBaseBackend -ErrorAction SilentlyContinue
  )
  foreach ($currentProcess in $currentProcesses) {
    if ($existingIds -notcontains $currentProcess.Id) {
      Stop-Process -Id $currentProcess.Id -Force -ErrorAction SilentlyContinue
    }
  }

  $env:KNOWBASE_BACKEND_PORT = $previousPort
  $env:KNOWBASE_DATA_DIR = $previousDataDir

  foreach ($logPath in @($stdoutPath, $stderrPath)) {
    if (Test-Path -LiteralPath $logPath) {
      Remove-Item -LiteralPath $logPath -Force
    }
  }

  if ($usingDefaultDataDir -and (Test-Path -LiteralPath $DataDir)) {
    $resolvedTempRoot = Resolve-Path -LiteralPath $workspaceTempRoot
    $resolvedDataDir = Resolve-Path -LiteralPath $DataDir
    if (-not $resolvedDataDir.Path.StartsWith($resolvedTempRoot.Path)) {
      throw "Refusing to remove health-check data directory outside workspace temp directory: $($resolvedDataDir.Path)"
    }
    Remove-Item -LiteralPath $resolvedDataDir.Path -Recurse -Force
  }
}
