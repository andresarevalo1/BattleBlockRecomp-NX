#!/usr/bin/env pwsh
# Prepara la carpeta game/ de la SD a partir de TU copia extraida del XBLA.
#
#   .\tools\preparar-juego.ps1 -Xbla "D:\BattleBlock Theater (World) (XBLA)\58410A30\000D0000"
#   .\tools\preparar-juego.ps1 -Xbla "D:\...\000D0000" -Destino "E:\sd\switch\battleblock_theater\game"
#
# El port NO incluye el contenido del juego (es material con derechos de The
# Behemoth): cada uno usa su propia copia. Este script solo copia y verifica
# la tuya, y comprueba que sea la version que el port soporta.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Xbla,

    [Parameter(Position = 1)]
    [string]$Destino = ".\game"
)

$ErrorActionPreference = 'Stop'

$ExpectedXexSha256 = '87A7C33F5C039DC24796173E22D9FF0D16C5E3663B73F77CDC81FB020250979F'

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    [ok] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "    [!]  $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "    [x]  $msg" -ForegroundColor Red }

if (-not (Test-Path -LiteralPath $Xbla)) {
    Write-Err "No existe la ruta: $Xbla"
    Write-Host ""
    Write-Host "Debes pasar la carpeta donde esta tu XBLA extraido, la que"
    Write-Host "contiene 'default.xex' y 'GameData/'. Si tu copia es un .iso o"
    Write-Host "un paquete de la Tienda de Xbox 360, primero extraela con"
    Write-Host "una herramienta de STFS (por ejemplo 'xbextract' o el"
    Write-Host "extractor de STFS que uses)."
    exit 1
}

$xex = Join-Path $Xbla 'default.xex'
if (-not (Test-Path -LiteralPath $xex)) {
    Write-Err "No hay 'default.xex' en $Xbla"
    Write-Host ""
    Write-Host "La carpeta indicada no es el XBLA extraido. Debe contener:"
    Write-Host "    default.xex"
    Write-Host "    GameData\"
    exit 1
}

Write-Step "Comprobando el ejecutable"
$hash = (Get-FileHash -LiteralPath $xex -Algorithm SHA256).Hash
if ($hash -ne $ExpectedXexSha256) {
    Write-Err "SHA-256 distinto al esperado."
    Write-Host "    esperado: $ExpectedXexSha256"
    Write-Host "    obtenido: $hash"
    Write-Host ""
    Write-Host "Este port solo soporta esta version exacta:"
    Write-Host "    TitleID 58410A30 - MediaID 1CF0A928 - v0.0.0.5 (2013-03-10)"
    exit 1
}
Write-Ok "default.xex verificado (SHA-256 correcto)"

if (-not (Test-Path -LiteralPath (Join-Path $Xbla 'GameData'))) {
    Write-Err "No hay 'GameData/' en $Xbla"
    exit 1
}

Write-Step "Copiando a $Destino"
New-Item -ItemType Directory -Path $Destino -Force | Out-Null

$copied = 0
$bytes = 0L
Get-ChildItem -LiteralPath $Xbla -Force | ForEach-Object {
    $target = Join-Path $Destino $_.Name
    if ($_.PSIsContainer) {
        Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force
    } else {
        Copy-Item -LiteralPath $_.FullName -Destination $target -Force
        $copied++
        $bytes += $_.Length
    }
}

$all = Get-ChildItem -LiteralPath $Destino -Recurse -File -Force
$total = ($all | Measure-Object -Property Length -Sum).Sum
Write-Ok ("{0} ficheros, {1:N1} MB en {2}" -f $all.Count, ($total / 1MB), $Destino)

Write-Step "Recordatorio"
Write-Host "    Copia esa carpeta como 'game' dentro de:"
Write-Host "        /switch/battleblock_theater/game"
Write-Host "    y copia el NRO en:"
Write-Host "        /switch/battleblock_theater/battleblock_theater.nro"
