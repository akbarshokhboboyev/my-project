$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$destination = $PSScriptRoot

function Paint-Shield($graphics, [float]$left, [float]$top, [float]$size) {
    $points = [Drawing.PointF[]]@(
        [Drawing.PointF]::new($left + $size * 0.5, $top),
        [Drawing.PointF]::new($left + $size * 0.94, $top + $size * 0.18),
        [Drawing.PointF]::new($left + $size * 0.88, $top + $size * 0.62),
        [Drawing.PointF]::new($left + $size * 0.71, $top + $size * 0.86),
        [Drawing.PointF]::new($left + $size * 0.5, $top + $size),
        [Drawing.PointF]::new($left + $size * 0.29, $top + $size * 0.86),
        [Drawing.PointF]::new($left + $size * 0.12, $top + $size * 0.62),
        [Drawing.PointF]::new($left + $size * 0.06, $top + $size * 0.18)
    )
    $fill = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#81EFCF'))
    $pen = [Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml('#0B2341'), $size * 0.075)
    $pen.StartCap = [Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
    try {
        $graphics.FillPolygon($fill, $points)
        $check = [Drawing.PointF[]]@(
            [Drawing.PointF]::new($left + $size * 0.3, $top + $size * 0.49),
            [Drawing.PointF]::new($left + $size * 0.45, $top + $size * 0.64),
            [Drawing.PointF]::new($left + $size * 0.73, $top + $size * 0.32)
        )
        $graphics.DrawLines($pen, $check)
    } finally { $fill.Dispose(); $pen.Dispose() }
}

foreach ($kind in @('feature', 'icon')) {
    $width = if ($kind -eq 'feature') { 1024 } else { 512 }
    $height = if ($kind -eq 'feature') { 500 } else { 512 }
    $bitmap = [Drawing.Bitmap]::new($width, $height, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $rectangle = [Drawing.Rectangle]::new(0, 0, $width, $height)
    $background = [Drawing.Drawing2D.LinearGradientBrush]::new($rectangle,
        [Drawing.ColorTranslator]::FromHtml('#071A31'), [Drawing.ColorTranslator]::FromHtml('#124C66'), 20)
    try {
        $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.TextRenderingHint = [Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $graphics.FillRectangle($background, $rectangle)
        if ($kind -eq 'feature') {
            Paint-Shield $graphics 713 96 258
            $title = [Drawing.Font]::new('Arial', 48, [Drawing.FontStyle]::Bold, [Drawing.GraphicsUnit]::Pixel)
            $subtitle = [Drawing.Font]::new('Arial', 25, [Drawing.FontStyle]::Regular, [Drawing.GraphicsUnit]::Pixel)
            $ink = [Drawing.SolidBrush]::new([Drawing.Color]::White)
            $muted = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#BDCEDC'))
            try {
                $graphics.DrawString('SHIELDGUARD', $title, $ink, 62, 170)
                $graphics.DrawString('Raqamli xavfsizligingiz uchun', $subtitle, $muted, 64, 237)
            } finally { $title.Dispose(); $subtitle.Dispose(); $ink.Dispose(); $muted.Dispose() }
        } else {
            Paint-Shield $graphics 111 90 290
        }
        $fileName = if ($kind -eq 'feature') { 'feature_graphic_v3.png' } else { 'store_icon_v3.png' }
        $bitmap.Save((Join-Path $destination $fileName), [Drawing.Imaging.ImageFormat]::Png)
        Write-Output "$fileName $width x $height RGB"
    } finally { $graphics.Dispose(); $background.Dispose(); $bitmap.Dispose() }
}
