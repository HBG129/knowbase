$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$iconDir = Join-Path $repoRoot "frontend\src-tauri\icons"
New-Item -ItemType Directory -Force -Path $iconDir | Out-Null

$svgPath = Join-Path $iconDir "icon.svg"
$pngPath = Join-Path $iconDir "icon-512.png"
$icoPath = Join-Path $iconDir "icon.ico"

$svg = @'
<svg width="512" height="512" viewBox="0 0 512 512" fill="none" xmlns="http://www.w3.org/2000/svg">
  <title>KnowBase desktop app icon</title>
  <desc>A geometric K mark with a connected knowledge path for the KnowBase AI knowledge base app.</desc>
  <defs>
    <linearGradient id="bg" x1="78" y1="46" x2="448" y2="466" gradientUnits="userSpaceOnUse">
      <stop stop-color="#0A0F1F"/>
      <stop offset="0.48" stop-color="#060910"/>
      <stop offset="1" stop-color="#101726"/>
    </linearGradient>
    <linearGradient id="accent" x1="146" y1="124" x2="367" y2="377" gradientUnits="userSpaceOnUse">
      <stop stop-color="#5EF2FF"/>
      <stop offset="0.52" stop-color="#7C5CFF"/>
      <stop offset="1" stop-color="#B7FF5A"/>
    </linearGradient>
    <filter id="glow" x="80" y="76" width="352" height="360" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">
      <feGaussianBlur stdDeviation="10" result="blur"/>
      <feColorMatrix in="blur" type="matrix" values="0 0 0 0 0.36 0 0 0 0 0.8 0 0 0 0 1 0 0 0 0.55 0"/>
      <feBlend in="SourceGraphic"/>
    </filter>
  </defs>
  <rect x="32" y="32" width="448" height="448" rx="108" fill="url(#bg)"/>
  <rect x="41" y="41" width="430" height="430" rx="100" stroke="white" stroke-opacity="0.10" stroke-width="18"/>
  <path d="M146 166C188 129 256 114 326 134C345 139 362 146 378 155" stroke="white" stroke-opacity="0.12" stroke-width="22" stroke-linecap="round"/>
  <path d="M138 339C184 384 261 400 340 373C355 368 369 361 383 353" stroke="white" stroke-opacity="0.10" stroke-width="22" stroke-linecap="round"/>
  <g filter="url(#glow)">
    <path d="M178 142V370" stroke="#F7FBFF" stroke-width="48" stroke-linecap="round"/>
    <path d="M213 256L335 151" stroke="#F7FBFF" stroke-width="48" stroke-linecap="round"/>
    <path d="M216 258L348 366" stroke="#F7FBFF" stroke-width="48" stroke-linecap="round"/>
    <path d="M214 255C256 237 301 230 356 246" stroke="url(#accent)" stroke-width="16" stroke-linecap="round"/>
    <circle cx="214" cy="255" r="19" fill="#5EF2FF"/>
    <circle cx="294" cy="234" r="15" fill="#7C5CFF"/>
    <circle cx="356" cy="246" r="18" fill="#B7FF5A"/>
  </g>
  <path d="M178 142V370" stroke="#06101A" stroke-opacity="0.18" stroke-width="12" stroke-linecap="round"/>
  <circle cx="384" cy="128" r="8" fill="white" fill-opacity="0.28"/>
  <circle cx="118" cy="384" r="6" fill="white" fill-opacity="0.20"/>
</svg>
'@

Set-Content -LiteralPath $svgPath -Value $svg -Encoding UTF8

Add-Type -AssemblyName System.Drawing

function New-RoundedRectanglePath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $path.AddArc($x, $y, $d, $d, 180, 90)
  $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  return $path
}

function New-IconBitmap([int]$Size) {
  $bitmap = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

  $scale = $Size / 512.0
  $rect = New-Object System.Drawing.RectangleF (32 * $scale), (32 * $scale), (448 * $scale), (448 * $scale)
  $bgPath = New-RoundedRectanglePath $rect.X $rect.Y $rect.Width $rect.Height (108 * $scale)
  $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(255, 10, 15, 31)), ([System.Drawing.Color]::FromArgb(255, 16, 23, 38)), 135
  $graphics.FillPath($bgBrush, $bgPath)

  $borderPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(28, 255, 255, 255)), ([Math]::Max(1, 16 * $scale))
  $graphics.DrawPath($borderPen, $bgPath)

  $cardPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(34, 255, 255, 255)), ([Math]::Max(1, 18 * $scale))
  $cardPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $cardPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $graphics.DrawBezier($cardPen, 146*$scale,166*$scale, 194*$scale,126*$scale, 292*$scale,118*$scale, 378*$scale,155*$scale)
  $graphics.DrawBezier($cardPen, 138*$scale,339*$scale, 196*$scale,395*$scale, 293*$scale,395*$scale, 383*$scale,353*$scale)

  $whitePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(248, 247, 251, 255)), ([Math]::Max(2, 48 * $scale))
  $whitePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $whitePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $whitePen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $graphics.DrawLine($whitePen, 178*$scale,142*$scale, 178*$scale,370*$scale)
  $graphics.DrawLine($whitePen, 213*$scale,256*$scale, 335*$scale,151*$scale)
  $graphics.DrawLine($whitePen, 216*$scale,258*$scale, 348*$scale,366*$scale)

  $accentPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 94, 242, 255)), ([Math]::Max(2, 16 * $scale))
  $accentPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $accentPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $graphics.DrawBezier($accentPen, 214*$scale,255*$scale, 251*$scale,239*$scale, 305*$scale,231*$scale, 356*$scale,246*$scale)

  $nodeColors = @(
    [System.Drawing.Color]::FromArgb(255, 94, 242, 255),
    [System.Drawing.Color]::FromArgb(255, 124, 92, 255),
    [System.Drawing.Color]::FromArgb(255, 183, 255, 90)
  )
  $nodes = @(
    @(214,255,19),
    @(294,234,15),
    @(356,246,18)
  )
  for ($i = 0; $i -lt $nodes.Count; $i++) {
    $node = $nodes[$i]
    $brush = New-Object System.Drawing.SolidBrush $nodeColors[$i]
    $x = ($node[0] - $node[2]) * $scale
    $y = ($node[1] - $node[2]) * $scale
    $d = ($node[2] * 2) * $scale
    $graphics.FillEllipse($brush, $x, $y, $d, $d)
    $brush.Dispose()
  }

  $innerCut = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(38, 6, 16, 26)), ([Math]::Max(1, 12 * $scale))
  $innerCut.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $innerCut.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $graphics.DrawLine($innerCut, 178*$scale,142*$scale, 178*$scale,370*$scale)

  $graphics.Dispose()
  return $bitmap
}

function Convert-BitmapToPngBytes([System.Drawing.Bitmap]$Bitmap) {
  $stream = New-Object System.IO.MemoryStream
  $Bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
  return ,$stream.ToArray()
}

function Write-Ico([string]$Path, [int[]]$Sizes) {
  $images = @()
  foreach ($size in $Sizes) {
    $bitmap = New-IconBitmap $size
    try {
      $images += ,@{
        Size = $size
        Bytes = Convert-BitmapToPngBytes $bitmap
      }
    }
    finally {
      $bitmap.Dispose()
    }
  }

  $stream = New-Object System.IO.MemoryStream
  $writer = New-Object System.IO.BinaryWriter $stream
  $writer.Write([UInt16]0)
  $writer.Write([UInt16]1)
  $writer.Write([UInt16]$images.Count)
  $offset = 6 + (16 * $images.Count)

  foreach ($image in $images) {
    $sizeByte = if ($image.Size -eq 256) { 0 } else { $image.Size }
    $writer.Write([byte]$sizeByte)
    $writer.Write([byte]$sizeByte)
    $writer.Write([byte]0)
    $writer.Write([byte]0)
    $writer.Write([UInt16]1)
    $writer.Write([UInt16]32)
    $writer.Write([UInt32]$image.Bytes.Length)
    $writer.Write([UInt32]$offset)
    $offset += $image.Bytes.Length
  }

  foreach ($image in $images) {
    $writer.Write([byte[]]$image.Bytes)
  }

  [System.IO.File]::WriteAllBytes($Path, $stream.ToArray())
  $writer.Dispose()
  $stream.Dispose()
}

$preview = New-IconBitmap 512
try {
  $preview.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
  $preview.Dispose()
}

Write-Ico $icoPath @(16, 24, 32, 48, 64, 128, 256)

Write-Output "Desktop icon generated."
Write-Output "SVG: $svgPath"
Write-Output "PNG: $pngPath"
Write-Output "ICO: $icoPath"
