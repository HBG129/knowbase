param(
  [Parameter(Mandatory = $true)]
  [string]$Path,

  [Parameter(Mandatory = $true)]
  [string]$CertificateThumbprint,

  [Parameter(Mandatory = $true)]
  [string]$TimestampUrl
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

$resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
if (-not $resolved) {
  Fail "File to sign was not found: $Path"
}

$timestampUri = $null
if (-not [Uri]::TryCreate($TimestampUrl, [UriKind]::Absolute, [ref]$timestampUri) -or
    $timestampUri.Scheme -notin @("http", "https")) {
  Fail "TimestampUrl must be an absolute HTTP or HTTPS URL."
}

& (Join-Path $PSScriptRoot "check-signing-certificate.ps1") `
  -CertificateThumbprint $CertificateThumbprint
if (-not $?) {
  exit 1
}

$signToolCommand = Get-Command "signtool.exe" -ErrorAction SilentlyContinue
$signToolPath = if ($signToolCommand) { $signToolCommand.Source } else { $null }
if (-not $signToolPath) {
  $kitsRoot = Join-Path ${env:ProgramFiles(x86)} "Windows Kits\10\bin"
  if (Test-Path -LiteralPath $kitsRoot) {
    $signToolPath = Get-ChildItem -LiteralPath $kitsRoot -Filter "signtool.exe" -File -Recurse `
      -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -match "\\x64\\signtool\.exe$" } |
      Sort-Object FullName -Descending |
      Select-Object -First 1 -ExpandProperty FullName
  }
}
if (-not $signToolPath) {
  Fail "signtool.exe was not found. Install the Windows SDK signing tools."
}

$normalizedThumbprint = ($CertificateThumbprint -replace "\s", "").ToUpperInvariant()
& $signToolPath sign /sha1 $normalizedThumbprint /fd SHA256 /tr $TimestampUrl /td SHA256 /v $resolved.Path
if ($LASTEXITCODE -ne 0) {
  Fail "signtool.exe failed with exit code $LASTEXITCODE."
}

& (Join-Path $PSScriptRoot "check-code-signature.ps1") -Path $resolved.Path `
  -ExpectedThumbprint $normalizedThumbprint -RequireTimestamp
if (-not $?) {
  exit 1
}
