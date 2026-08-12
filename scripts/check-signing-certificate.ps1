param(
  [Parameter(Mandatory = $true)]
  [string]$CertificateThumbprint
)

$ErrorActionPreference = "Stop"
$codeSigningEku = "1.3.6.1.5.5.7.3.3"
$normalizedThumbprint = ($CertificateThumbprint -replace "\s", "").ToUpperInvariant()

function Fail($Message) {
  Write-Error $Message
  exit 1
}

if ($normalizedThumbprint -notmatch "^[A-F0-9]{40}$") {
  Fail "Certificate thumbprint must contain exactly 40 hexadecimal characters."
}

$certificate = $null
$certificateStore = ""
foreach ($store in @("Cert:\CurrentUser\My", "Cert:\LocalMachine\My")) {
  $candidate = Get-ChildItem -LiteralPath $store -ErrorAction SilentlyContinue |
    Where-Object { (($_.Thumbprint -replace "\s", "").ToUpperInvariant()) -eq $normalizedThumbprint } |
    Select-Object -First 1
  if ($candidate) {
    $certificate = $candidate
    $certificateStore = $store
    break
  }
}

if (-not $certificate) {
  Fail "Code-signing certificate was not found in Cert:\CurrentUser\My or Cert:\LocalMachine\My."
}
if (-not $certificate.HasPrivateKey) {
  Fail "Code-signing certificate does not have an accessible private key."
}

$now = Get-Date
if ($certificate.NotBefore -gt $now) {
  Fail "Code-signing certificate is not valid yet."
}
if ($certificate.NotAfter -le $now) {
  Fail "Code-signing certificate has expired."
}

$ekuOids = @($certificate.EnhancedKeyUsageList | ForEach-Object { [string]$_.ObjectId })
if ($codeSigningEku -notin $ekuOids) {
  Fail "Certificate does not include the Code Signing enhanced key usage ($codeSigningEku)."
}

Write-Output "Code-signing certificate is usable."
Write-Output "Store: $certificateStore"
Write-Output "Subject: $($certificate.Subject)"
Write-Output "Thumbprint: $($certificate.Thumbprint)"
Write-Output "Valid from: $($certificate.NotBefore.ToString('o'))"
Write-Output "Valid until: $($certificate.NotAfter.ToString('o'))"
