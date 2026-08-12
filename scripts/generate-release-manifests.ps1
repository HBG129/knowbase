param(
  [string]$OutputDir = "",

  [string]$Version = "0.1.0-rc.1",

  [string]$CommitSha = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $repoRoot "backend"
$frontendRoot = Join-Path $repoRoot "frontend"
$tauriRoot = Join-Path $frontendRoot "src-tauri"
if (-not $OutputDir) {
  $OutputDir = Join-Path (Split-Path -Parent $repoRoot) "artifacts\knowbase-release-manifests"
}

function Fail($Message) {
  Write-Error $Message
  exit 1
}

function Write-Utf8NoBom {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [string]$Content
  )

  $encoding = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

if ($Version -notmatch "^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$") {
  Fail "Version must be a semantic version such as 0.1.0-rc.1."
}

$uvCommand = Get-Command "uv" -ErrorAction SilentlyContinue
$uvPath = if ($uvCommand) { $uvCommand.Source } else { "" }
if (-not $uvPath) {
  $localUv = Join-Path $backendRoot ".venv\Scripts\uv.exe"
  if (Test-Path -LiteralPath $localUv) { $uvPath = $localUv }
}
if (-not $uvPath) { Fail "uv was not found. Install the pinned release tool before generating manifests." }
if (-not (Get-Command "npm" -ErrorAction SilentlyContinue)) { Fail "npm was not found." }
if (-not (Get-Command "cargo" -ErrorAction SilentlyContinue)) { Fail "cargo was not found." }

if (-not $CommitSha) {
  $CommitSha = (& git -C $repoRoot rev-parse HEAD 2>$null).Trim()
}
if ($CommitSha -notmatch "^[A-Fa-f0-9]{40}$") { Fail "CommitSha must be a full 40-character Git commit SHA." }

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$resolvedOutput = (Resolve-Path -LiteralPath $OutputDir).Path
$backendSbom = Join-Path $resolvedOutput "backend-sbom.cdx.json"
$frontendSbom = Join-Path $resolvedOutput "frontend-sbom.cdx.json"
$rustDependencies = Join-Path $resolvedOutput "rust-dependencies.json"
$buildMetadataPath = Join-Path $resolvedOutput "BUILD_METADATA.json"

& $uvPath export --project $backendRoot --locked --no-dev --format cyclonedx1.5 `
  --output-file $backendSbom | Out-Null
if ($LASTEXITCODE -ne 0) { Fail "Backend CycloneDX SBOM generation failed." }

Push-Location $frontendRoot
try {
  $frontendSbomContent = & npm sbom --package-lock-only --omit dev `
    --sbom-format cyclonedx --sbom-type application | Out-String
  if ($LASTEXITCODE -ne 0) { Fail "Frontend CycloneDX SBOM generation failed." }
  Write-Utf8NoBom -Path $frontendSbom -Content $frontendSbomContent
}
finally {
  Pop-Location
}

Push-Location $tauriRoot
try {
  $cargoMetadata = & cargo metadata --locked --format-version 1 | ConvertFrom-Json
  if ($LASTEXITCODE -ne 0) { Fail "Rust dependency metadata generation failed." }
  $rustManifest = [ordered]@{
    format = "KnowBase Rust dependency manifest"
    version = 1
    packages = @($cargoMetadata.packages | Sort-Object name, version | ForEach-Object {
      [ordered]@{
        name = $_.name
        version = $_.version
        source = $_.source
        license = $_.license
        repository = $_.repository
      }
    })
  }
  $rustManifestContent = $rustManifest | ConvertTo-Json -Depth 5 | Out-String
  Write-Utf8NoBom -Path $rustDependencies -Content $rustManifestContent
}
finally {
  Pop-Location
}

$buildMetadata = [ordered]@{
  product = "KnowBase"
  release_version = $Version
  source_repository = "https://github.com/HBG129/knowbase"
  source_commit = $CommitSha.ToLowerInvariant()
  python_version = (& (Join-Path $backendRoot ".venv\Scripts\python.exe") --version 2>&1 | Out-String).Trim()
  uv_version = (& $uvPath --version | Out-String).Trim()
  node_version = (& node --version | Out-String).Trim()
  npm_version = (& npm --version | Out-String).Trim()
  rustc_version = (& rustc --version | Out-String).Trim()
  cargo_version = (& cargo --version | Out-String).Trim()
  lockfiles = [ordered]@{
    backend = "backend/uv.lock"
    frontend = "frontend/package-lock.json"
    rust = "frontend/src-tauri/Cargo.lock"
  }
}
$buildMetadataContent = $buildMetadata | ConvertTo-Json -Depth 5 | Out-String
Write-Utf8NoBom -Path $buildMetadataPath -Content $buildMetadataContent

foreach ($path in @($backendSbom, $frontendSbom, $rustDependencies, $buildMetadataPath)) {
  $parsed = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
  if (-not $parsed) { Fail "Generated manifest is empty or invalid JSON: $path" }
}

Write-Output "Release manifests generated."
Write-Output "Output: $resolvedOutput"
