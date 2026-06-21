param(
  [Parameter(Mandatory = $true)]
  [string]$Path,

  [switch]$AllowUnsigned
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

$resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
if (-not $resolved) {
  Fail "File was not found: $Path"
}

$signature = Get-AuthenticodeSignature -LiteralPath $resolved.Path

Write-Output "Code signature status: $($signature.Status)"
Write-Output "File: $($resolved.Path)"

if ($signature.SignerCertificate) {
  Write-Output "Signer: $($signature.SignerCertificate.Subject)"
  Write-Output "Thumbprint: $($signature.SignerCertificate.Thumbprint)"
}

if ($signature.Status -ne "Valid" -and -not $AllowUnsigned) {
  Fail "Code signature is not valid. Status: $($signature.Status). Use -AllowUnsigned only for internal validation builds."
}
