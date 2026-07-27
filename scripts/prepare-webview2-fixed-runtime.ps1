param(
  [string]$CabPath = ""
)

$ErrorActionPreference = "Stop"

$version = "150.0.4078.99"
$fileName = "Microsoft.WebView2.FixedVersionRuntime.$version.x64.cab"
$downloadUrl = "https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/1c394b0d-2689-4d8b-af57-2f2018abccf6/$fileName"
$expectedSha256 = "2E69CDC3D304441562C7C2A8C21948C3B8E69DC7629D912EF853E41147220BDA"
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$tauriRoot = Join-Path $repoRoot "frontend\src-tauri"
$runtimeRoot = Join-Path $tauriRoot "WebView2.FixedVersionRuntime.x64"
$runtimeExe = Join-Path $runtimeRoot "msedgewebview2.exe"
$cacheRoot = Join-Path $tauriRoot ".webview2-cache"
$cachedCab = Join-Path $cacheRoot $fileName

function Assert-PathInsideRepo {
  param([string]$Path)

  $absolutePath = [System.IO.Path]::GetFullPath($Path)
  $repoPrefix = $repoRoot.TrimEnd("\") + "\"
  if (-not $absolutePath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to modify a path outside the repository: $absolutePath"
  }
}

function Test-PreparedRuntime {
  if (-not (Test-Path -LiteralPath $runtimeExe -PathType Leaf)) {
    return $false
  }

  $actualVersion = (Get-Item -LiteralPath $runtimeExe).VersionInfo.ProductVersion
  return $actualVersion -eq $version
}

if ($CabPath) {
  $resolvedCab = (Resolve-Path -LiteralPath $CabPath).Path
}
else {
  New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null
  Assert-PathInsideRepo -Path $cacheRoot

  if (Test-Path -LiteralPath $cachedCab -PathType Leaf) {
    $cachedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $cachedCab).Hash
    if ($cachedHash -ne $expectedSha256) {
      Remove-Item -LiteralPath $cachedCab -Force
    }
  }

  if (-not (Test-Path -LiteralPath $cachedCab -PathType Leaf)) {
    $partialCab = "$cachedCab.partial"
    Assert-PathInsideRepo -Path $partialCab
    $downloadAttempts = 3
    for ($attempt = 1; $attempt -le $downloadAttempts; $attempt++) {
      Remove-Item -LiteralPath $partialCab -Force -ErrorAction SilentlyContinue
      try {
        Write-Host "Downloading WebView2 Fixed Version Runtime $version (attempt $attempt of $downloadAttempts)..."
        Invoke-WebRequest -UseBasicParsing -Uri $downloadUrl -OutFile $partialCab
        Move-Item -LiteralPath $partialCab -Destination $cachedCab
        break
      }
      catch {
        Remove-Item -LiteralPath $partialCab -Force -ErrorAction SilentlyContinue
        if ($attempt -eq $downloadAttempts) {
          throw
        }
        Start-Sleep -Seconds (2 * $attempt)
      }
    }
  }

  $resolvedCab = $cachedCab
}

$actualSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $resolvedCab).Hash
if ($actualSha256 -ne $expectedSha256) {
  throw "WebView2 CAB SHA256 mismatch. Expected $expectedSha256, got $actualSha256."
}

$extractRoot = Join-Path $tauriRoot (".webview2-extract-" + [Guid]::NewGuid().ToString("N"))
$extractedRuntime = Join-Path $extractRoot "Microsoft.WebView2.FixedVersionRuntime.$version.x64"
Assert-PathInsideRepo -Path $extractRoot
Assert-PathInsideRepo -Path $runtimeRoot

try {
  New-Item -ItemType Directory -Force -Path $extractRoot | Out-Null
  & "$env:SystemRoot\System32\expand.exe" $resolvedCab -F:* $extractRoot | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "WebView2 CAB extraction failed with exit code $LASTEXITCODE."
  }

  $extractedExe = Join-Path $extractedRuntime "msedgewebview2.exe"
  if (-not (Test-Path -LiteralPath $extractedExe -PathType Leaf)) {
    throw "Extracted WebView2 runtime is missing msedgewebview2.exe."
  }

  $extractedVersion = (Get-Item -LiteralPath $extractedExe).VersionInfo.ProductVersion
  if ($extractedVersion -ne $version) {
    throw "Extracted WebView2 runtime version mismatch. Expected $version, got $extractedVersion."
  }

  $signature = Get-AuthenticodeSignature -LiteralPath $extractedExe
  if ($signature.Status -ne "Valid") {
    throw "Extracted WebView2 runtime signature is not valid: $($signature.Status)."
  }

  if (Test-Path -LiteralPath $runtimeRoot) {
    Remove-Item -LiteralPath $runtimeRoot -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path $runtimeRoot | Out-Null
  Get-ChildItem -LiteralPath $extractedRuntime -Force |
    Copy-Item -Destination $runtimeRoot -Recurse -Force
}
finally {
  if (Test-Path -LiteralPath $extractRoot) {
    Remove-Item -LiteralPath $extractRoot -Recurse -Force
  }
}

if (-not (Test-PreparedRuntime)) {
  throw "WebView2 Fixed Version Runtime preparation did not produce a usable runtime."
}

Write-Host "WebView2 Fixed Version Runtime $version is ready: $runtimeRoot"
