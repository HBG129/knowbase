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
  <desc>A luminous knowledge cube with document layers for the KnowBase app.</desc>
  <defs>
    <linearGradient id="bg" x1="54" y1="40" x2="454" y2="474" gradientUnits="userSpaceOnUse">
      <stop stop-color="#101827"/>
      <stop offset="0.5" stop-color="#060A12"/>
      <stop offset="1" stop-color="#0F1726"/>
    </linearGradient>
    <linearGradient id="cubeTop" x1="166" y1="116" x2="360" y2="246" gradientUnits="userSpaceOnUse">
      <stop stop-color="#EAFBFF" stop-opacity="0.98"/>
      <stop offset="1" stop-color="#5EF2FF" stop-opacity="0.72"/>
    </linearGradient>
    <linearGradient id="cubeLeft" x1="145" y1="189" x2="256" y2="377" gradientUnits="userSpaceOnUse">
      <stop stop-color="#6D7CFF" stop-opacity="0.78"/>
      <stop offset="1" stop-color="#141C3B" stop-opacity="0.82"/>
    </linearGradient>
    <linearGradient id="cubeRight" x1="360" y1="188" x2="255" y2="376" gradientUnits="userSpaceOnUse">
      <stop stop-color="#B8FF6A" stop-opacity="0.74"/>
      <stop offset="1" stop-color="#132B30" stop-opacity="0.78"/>
    </linearGradient>
    <filter id="softGlow" x="80" y="80" width="352" height="352" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">
      <feGaussianBlur stdDeviation="18"/>
      <feColorMatrix type="matrix" values="0 0 0 0 0.24 0 0 0 0 0.78 0 0 0 0 1 0 0 0 0.42 0"/>
    </filter>
  </defs>
  <rect x="32" y="32" width="448" height="448" rx="108" fill="url(#bg)"/>
  <rect x="43" y="43" width="426" height="426" rx="98" stroke="white" stroke-opacity="0.10" stroke-width="18"/>
  <circle cx="256" cy="254" r="132" fill="#5EF2FF" opacity="0.14" filter="url(#softGlow)"/>
  <path d="M256 118L372 188L256 258L140 188L256 118Z" fill="url(#cubeTop)" stroke="#EAFBFF" stroke-opacity="0.70" stroke-width="5" stroke-linejoin="round"/>
  <path d="M140 188L256 258V388L140 318V188Z" fill="url(#cubeLeft)" stroke="#A7B0FF" stroke-opacity="0.52" stroke-width="5" stroke-linejoin="round"/>
  <path d="M372 188L256 258V388L372 318V188Z" fill="url(#cubeRight)" stroke="#C8FF90" stroke-opacity="0.48" stroke-width="5" stroke-linejoin="round"/>
  <path d="M179 207L256 252L333 207" stroke="#06101A" stroke-opacity="0.34" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M181 242L256 286L331 242" stroke="#EAFBFF" stroke-opacity="0.60" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M181 279L256 323L331 279" stroke="#EAFBFF" stroke-opacity="0.42" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M178 318L256 364L334 318" stroke="#EAFBFF" stroke-opacity="0.28" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>
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

function New-Point([double]$x, [double]$y, [double]$scale) {
  return New-Object System.Drawing.PointF ([float]($x * $scale)), ([float]($y * $scale))
}

function New-Points([double[][]]$Values, [double]$Scale) {
  $points = New-Object 'System.Drawing.PointF[]' $Values.Count
  for ($i = 0; $i -lt $Values.Count; $i++) {
    $points[$i] = New-Point $Values[$i][0] $Values[$i][1] $Scale
  }
  return $points
}

function New-SolidBrush([int]$a, [int]$r, [int]$g, [int]$b) {
  return New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($a, $r, $g, $b))
}

function New-Pen([int]$a, [int]$r, [int]$g, [int]$b, [float]$width) {
  $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb($a, $r, $g, $b)), $width
  $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  return $pen
}

function Fill-Polygon([System.Drawing.Graphics]$Graphics, [System.Drawing.Brush]$Brush, [double[][]]$Points, [double]$Scale) {
  $Graphics.FillPolygon($Brush, (New-Points $Points $Scale))
}

function Draw-Polygon([System.Drawing.Graphics]$Graphics, [System.Drawing.Pen]$Pen, [double[][]]$Points, [double]$Scale) {
  $Graphics.DrawPolygon($Pen, (New-Points $Points $Scale))
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
  $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(255, 16, 24, 39)), ([System.Drawing.Color]::FromArgb(255, 6, 10, 18)), 135
  $graphics.FillPath($bgBrush, $bgPath)

  $borderPen = New-Pen 28 255 255 255 ([Math]::Max(1, 16 * $scale))
  $graphics.DrawPath($borderPen, $bgPath)

  $glowBrush = New-SolidBrush 32 94 242 255
  $graphics.FillEllipse($glowBrush, 108*$scale, 104*$scale, 296*$scale, 296*$scale)

  $topBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.RectangleF (140*$scale), (118*$scale), (232*$scale), (140*$scale)), ([System.Drawing.Color]::FromArgb(248, 234, 251, 255)), ([System.Drawing.Color]::FromArgb(184, 94, 242, 255)), 35
  $leftBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.RectangleF (140*$scale), (188*$scale), (116*$scale), (200*$scale)), ([System.Drawing.Color]::FromArgb(196, 109, 124, 255)), ([System.Drawing.Color]::FromArgb(210, 20, 28, 59)), 90
  $rightBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.RectangleF (256*$scale), (188*$scale), (116*$scale), (200*$scale)), ([System.Drawing.Color]::FromArgb(190, 184, 255, 106)), ([System.Drawing.Color]::FromArgb(200, 19, 43, 48)), 90

  $top = @(@(256,118), @(372,188), @(256,258), @(140,188))
  $left = @(@(140,188), @(256,258), @(256,388), @(140,318))
  $right = @(@(372,188), @(256,258), @(256,388), @(372,318))
  Fill-Polygon $graphics $topBrush $top $scale
  Fill-Polygon $graphics $leftBrush $left $scale
  Fill-Polygon $graphics $rightBrush $right $scale

  $topEdge = New-Pen 178 234 251 255 ([Math]::Max(1, 5 * $scale))
  $leftEdge = New-Pen 116 167 176 255 ([Math]::Max(1, 5 * $scale))
  $rightEdge = New-Pen 108 200 255 144 ([Math]::Max(1, 5 * $scale))
  Draw-Polygon $graphics $topEdge $top $scale
  Draw-Polygon $graphics $leftEdge $left $scale
  Draw-Polygon $graphics $rightEdge $right $scale

  $shadowPen = New-Pen 72 6 16 26 ([Math]::Max(1, 10 * $scale))
  $graphics.DrawLines($shadowPen, (New-Points @(@(179,207), @(256,252), @(333,207)) $scale))

  $layerPen1 = New-Pen 150 234 251 255 ([Math]::Max(1, 8 * $scale))
  $layerPen2 = New-Pen 106 234 251 255 ([Math]::Max(1, 8 * $scale))
  $layerPen3 = New-Pen 72 234 251 255 ([Math]::Max(1, 8 * $scale))
  $graphics.DrawLines($layerPen1, (New-Points @(@(181,242), @(256,286), @(331,242)) $scale))
  $graphics.DrawLines($layerPen2, (New-Points @(@(181,279), @(256,323), @(331,279)) $scale))
  $graphics.DrawLines($layerPen3, (New-Points @(@(178,318), @(256,364), @(334,318)) $scale))

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
