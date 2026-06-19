$ErrorActionPreference = "Stop"

function Fail($Messages) {
  foreach ($message in $Messages) {
    Write-Error $message
  }
  exit 1
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$gitFiles = & git -c "safe.directory=$repoRoot" -C $repoRoot ls-files

if ($LASTEXITCODE -ne 0) {
  Fail @("Could not list tracked files with git ls-files.")
}

$blocked = New-Object System.Collections.Generic.List[string]

foreach ($file in $gitFiles) {
  $normalized = $file -replace '\\', '/'
  $name = Split-Path -Leaf $normalized

  if ($name -eq ".env") {
    $blocked.Add("$file matches blocked env file name")
    continue
  }

  if (($name -like ".env.*") -and ($name -ne ".env.example")) {
    $blocked.Add("$file matches blocked env variant")
    continue
  }

  if ($normalized -match '(^|/)(data|uploads|artifacts)(/|$)') {
    $blocked.Add("$file is under a blocked local/runtime directory")
    continue
  }

  if ($normalized -match '\.(db|sqlite|sqlite3)$') {
    $blocked.Add("$file matches blocked local database extension")
    continue
  }

  if ($normalized -match '(^|/)backend/(build|dist)(/|$)') {
    $blocked.Add("$file is under a blocked backend build output directory")
    continue
  }

  if ($normalized -match '(^|/)frontend/src-tauri/target(/|$)') {
    $blocked.Add("$file is under a blocked Tauri build output directory")
    continue
  }
}

if ($blocked.Count -gt 0) {
  Fail $blocked
}

Write-Output "Sensitive tracked-file check passed."
