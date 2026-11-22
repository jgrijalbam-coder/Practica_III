Add-Type -AssemblyName System.Drawing

$raiz = Split-Path -Parent $PSScriptRoot
$origen = Join-Path $raiz 'assets\icon\vista_launcher.png'
$recursos = Join-Path $raiz 'android\app\src\main\res'
$densidades = @(
    @{ Nombre = 'mipmap-mdpi'; Pixeles = 48 },
    @{ Nombre = 'mipmap-hdpi'; Pixeles = 72 },
    @{ Nombre = 'mipmap-xhdpi'; Pixeles = 96 },
    @{ Nombre = 'mipmap-xxhdpi'; Pixeles = 144 },
    @{ Nombre = 'mipmap-xxxhdpi'; Pixeles = 192 }
)

$imagen = [System.Drawing.Image]::FromFile($origen)
try {
    foreach ($densidad in $densidades) {
        $carpeta = Join-Path $recursos $densidad.Nombre
        $destino = Join-Path $carpeta 'ic_launcher.png'
        $temporal = Join-Path $carpeta 'ic_launcher.generated.png'
        $tamano = [int]$densidad.Pixeles
        $bitmap = [System.Drawing.Bitmap]::new($tamano, $tamano)
        try {
            $grafico = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $grafico.Clear([System.Drawing.Color]::Transparent)
                $grafico.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $grafico.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $grafico.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $grafico.DrawImage($imagen, 0, 0, $tamano, $tamano)
            }
            finally {
                $grafico.Dispose()
            }
            $bitmap.Save($temporal, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $bitmap.Dispose()
        }
        Move-Item -LiteralPath $temporal -Destination $destino -Force
    }
}
finally {
    $imagen.Dispose()
}

Write-Output 'Íconos de Android generados desde assets/icon/vista_launcher.png.'
