$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$chatPagePath = Join-Path $repoRoot "frontend\src\app\chat\page.tsx"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

if (-not (Test-Path -LiteralPath $chatPagePath)) {
  Fail "Missing chat page: $chatPagePath"
}

$chatPage = Get-Content -LiteralPath $chatPagePath -Raw -Encoding UTF8

if (-not $chatPage.Contains("setConversations((prev) => prev.filter((conv) => conv.id !== convId))")) {
  Fail "Deleted conversations are not removed from local UI state immediately."
}

if (-not $chatPage.Contains("await fetchConversations()")) {
  Fail "Conversation refresh after delete is not awaited."
}

Write-Output "Chat delete UX checks passed."
