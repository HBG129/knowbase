$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$apiPath = Join-Path $repoRoot "frontend\src\lib\api.ts"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

if (-not (Test-Path -LiteralPath $apiPath)) {
  Fail "Missing frontend API client: $apiPath"
}

$apiSource = Get-Content -LiteralPath $apiPath -Raw -Encoding UTF8

if (-not $apiSource.Contains("res.status === 204")) {
  Fail "Frontend API client does not explicitly handle 204 No Content responses."
}

if (-not $apiSource.Contains("return undefined as T")) {
  Fail "Frontend API client should return undefined for successful empty responses instead of parsing JSON."
}

Write-Output "Frontend empty-response API checks passed."
