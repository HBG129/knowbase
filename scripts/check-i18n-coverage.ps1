param(
  [string]$Root = ""
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

function U([int[]]$Codes) {
  return -join ($Codes | ForEach-Object { [char]$_ })
}

function Get-MarkedBlock($Content, $Language) {
  $startMarker = "// i18n:$Language-start"
  $endMarker = "// i18n:$Language-end"
  $start = $Content.IndexOf($startMarker)
  $end = $Content.IndexOf($endMarker)
  if ($start -lt 0 -or $end -lt 0 -or $end -le $start) {
    Fail "Missing or invalid $Language dictionary markers in frontend/src/lib/i18n.ts."
  }

  return $Content.Substring($start + $startMarker.Length, $end - $start - $startMarker.Length)
}

function Get-DictionaryKeys($Block, $Language) {
  $matches = [regex]::Matches($Block, '(?m)^\s*"(?<key>[a-zA-Z0-9._-]+)"\s*:')
  $keys = @($matches | ForEach-Object { $_.Groups["key"].Value })
  $duplicates = @($keys | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
  if ($duplicates.Count -gt 0) {
    Fail "Duplicate $Language translation keys: $($duplicates -join ', ')"
  }
  if ($keys.Count -eq 0) {
    Fail "No $Language translation keys were found."
  }

  return $keys
}

function Get-RepoRelativePath($RepoRoot, $FullPath) {
  return $FullPath.Substring($RepoRoot.Length).TrimStart('\', '/')
}

if (-not $Root) {
  $Root = Split-Path -Parent $PSScriptRoot
}

$repoRoot = Resolve-Path -LiteralPath $Root
$i18nPath = Join-Path $repoRoot.Path "frontend\src\lib\i18n.ts"
if (-not (Test-Path -LiteralPath $i18nPath)) {
  Fail "Missing frontend/src/lib/i18n.ts."
}

$i18nContent = Get-Content -LiteralPath $i18nPath -Raw -Encoding UTF8
$zhKeys = @(Get-DictionaryKeys (Get-MarkedBlock $i18nContent "zh") "zh")
$enKeys = @(Get-DictionaryKeys (Get-MarkedBlock $i18nContent "en") "en")

Write-Output "Dictionary key parity"
$missingInEnglish = @($zhKeys | Where-Object { $_ -notin $enKeys })
$missingInChinese = @($enKeys | Where-Object { $_ -notin $zhKeys })
if ($missingInEnglish.Count -gt 0 -or $missingInChinese.Count -gt 0) {
  Fail "Translation dictionaries differ. Missing in English: $($missingInEnglish -join ', '); missing in Chinese: $($missingInChinese -join ', ')."
}

Write-Output "Translation usage keys"
$sourceRoot = Join-Path $repoRoot.Path "frontend\src"
$sourceFiles = @(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -Include "*.ts", "*.tsx")
$unknownUsages = @()
foreach ($file in $sourceFiles) {
  $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  $matches = [regex]::Matches($content, '\bt\(\s*["''](?<key>[a-zA-Z0-9._-]+)["'']')
  foreach ($match in $matches) {
    $key = $match.Groups["key"].Value
    if ($key -notin $zhKeys) {
      $relativePath = Get-RepoRelativePath $repoRoot.Path $file.FullName
      $unknownUsages += "$relativePath -> $key"
    }
  }
}
if ($unknownUsages.Count -gt 0) {
  Fail "Unknown translation keys: $($unknownUsages -join '; ')"
}

Write-Output "Hardcoded customer-facing copy"
$customerFacingRoots = @(
  (Join-Path $sourceRoot "app"),
  (Join-Path $sourceRoot "components")
)
$forbiddenCopy = @(
  "Knowledge workspace online",
  "Build, search, and question",
  "Create your first knowledge base",
  "Activation path",
  "Recent conversations",
  "Upload source documents",
  "Start a cited conversation",
  "Conversations will appear here",
  "Create KB",
  "Upload files",
  "Ask with sources",
  "Set API Key",
  "Sign Out",
  "Select a dataset",
  "Recommended questions",
  "Analysis history",
  "Run analysis",
  "Generated SQL",
  "Query results",
  "No citations yet",
  "Something went wrong",
  "Try again"
)
$hardcodedHits = @()
foreach ($root in $customerFacingRoots) {
  foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File -Include "*.ts", "*.tsx") {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    foreach ($phrase in $forbiddenCopy) {
      if ($content.Contains($phrase)) {
        $relativePath = Get-RepoRelativePath $repoRoot.Path $file.FullName
        $hardcodedHits += "$relativePath -> $phrase"
      }
    }
  }
}
if ($hardcodedHits.Count -gt 0) {
  Fail "Hardcoded customer-facing copy remains: $($hardcodedHits -join '; ')"
}

$allowedVisibleLiterals = @("KnowBase", "API Key", "KB")
$literalHits = @()
foreach ($root in $customerFacingRoots) {
  foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File -Include "*.ts", "*.tsx") {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $relativePath = Get-RepoRelativePath $repoRoot.Path $file.FullName

    foreach ($match in [regex]::Matches($content, '>\s*(?<text>[A-Za-z][A-Za-z0-9 ,.?!''()/-]{1,})\s*<')) {
      $visibleText = $match.Groups["text"].Value.Trim()
      if ($visibleText -notin $allowedVisibleLiterals) {
        $literalHits += "$relativePath -> $visibleText"
      }
    }

    foreach ($match in [regex]::Matches($content, '(?<attribute>placeholder|title|aria-label)\s*=\s*["''](?<text>[^"'']*[A-Za-z][^"'']*)["'']')) {
      $visibleText = $match.Groups["text"].Value.Trim()
      if ($visibleText -notin $allowedVisibleLiterals) {
        $literalHits += "$relativePath -> $($match.Groups['attribute'].Value): $visibleText"
      }
    }
  }
}
if ($literalHits.Count -gt 0) {
  Fail "Literal customer-facing JSX copy must use t(): $($literalHits -join '; ')"
}

$mojibakeMarkers = @(
  (U @(0x93C5)),
  (U @(0x934F, 0x5D88)),
  (U @(0x6FB6, 0x8FAB)),
  (U @(0x7481, 0x5267, 0x7586)),
  (U @(0x95B0, 0x5D87, 0x7586)),
  (U @(0x5A13, 0x5474, 0x6ACE)),
  [char]0xFFFD
)
$mojibakeHits = @()
foreach ($file in $sourceFiles) {
  $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  foreach ($marker in $mojibakeMarkers) {
    if ($content.Contains([string]$marker)) {
      $relativePath = Get-RepoRelativePath $repoRoot.Path $file.FullName
      $mojibakeHits += "$relativePath -> $marker"
    }
  }
}
if ($mojibakeHits.Count -gt 0) {
  Fail "Possible mojibake remains in frontend source: $($mojibakeHits -join '; ')"
}

Write-Output "i18n coverage checks passed."
