#!/usr/bin/env pwsh
# Prepara la carpeta game/ de la SD a partir de TU copia del XBLA.
#
#   .\tools\preparar-juego.ps1 -Xbla "D:\BattleBlock Theater (World) (XBLA)\58410A30\000D0000"
#   .\tools\preparar-juego.ps1 -Xbla "D:\juego.iso"
#   .\tools\preparar-juego.ps1 -Xbla "D:\...\000D0000" -Destino "E:\sd\switch\battleblock_theater\game"
#
# Acepta la carpeta ya extraida o el .iso / .xiso del XBLA.
#
# El port NO incluye el contenido del juego (material con derechos de The
# Behemoth): cada uno usa su propia copia. Este script copia y verifica la
# tuya, y comprueba que sea la version que el port soporta.

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
function Write-Err($msg)  { Write-Host "    [x]  $msg" -ForegroundColor Red }

if (-not (Test-Path -LiteralPath $Xbla)) {
    Write-Err "No existe la ruta: $Xbla"
    exit 1
}

# --- 1. Si es un .iso, desempaquetarlo --------------------------------------
$base = $Xbla
if (Test-Path -LiteralPath $Xbla -PathType Leaf) {
    if ($Xbla -notmatch '\.(iso|xiso)$') {
        Write-Err "El fichero '$Xbla' no es un ISO."
        exit 1
    }
    $extract = Get-Command 'extract-xiso.exe' -ErrorAction SilentlyContinue
    if (-not $extract) { $extract = Get-Command 'extract-xiso' -ErrorAction SilentlyContinue }
    if (-not $extract) {
        Write-Err "'$Xbla' es un ISO y no esta 'extract-xiso' (Xbox-ISO-Lib)."
        Write-Host "    Instala Xbox-ISO-Lib, o extrae el ISO a mano y vuelve a"
        Write-Host "    pasar la carpeta resultante."
        exit 1
    }
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("bbt-xiso-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    Write-Step "Desempaquetando el ISO"
    & $extract.Source -i $Xbla $tmp
    if ($LASTEXITCODE -ne 0) { & $extract.Source $Xbla $tmp }
    $base = $tmp
    Write-Ok "ISO desempaquetado en $tmp"
}

# --- 2. Localizar default.xex -----------------------------------------------
$xex = Join-Path $base 'default.xex'
if (-not (Test-Path -LiteralPath $xex)) {
    $found = Get-ChildItem -LiteralPath $base -Recurse -File -Filter 'default.xex' -ErrorAction SilentlyContinue |
             Select-Object -First 1
    if ($found) {
        $xex = $found.FullName
        $base = $found.DirectoryName
        Write-Step "default.xex encontrado en $base"
    }
}

if (-not (Test-Path -LiteralPath $xex)) {
    Write-Err "No hay 'default.xex' en '$base'"
    Write-Host "    el ISO no es del XBLA de BattleBlock Theater, o no esta"
    Write-Host "    desempaquetado con extract-xiso."
    exit 1
}

# --- 3. Verificar el ejecutable ---------------------------------------------
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

if (-not (Test-Path -LiteralPath (Join-Path $base 'GameData'))) {
    Write-Err "No hay 'GameData/' junto al default.xex"
    exit 1
}

# --- 4. Copiar --------------------------------------------------------------
Write-Step "Copiando a $Destino"
New-Item -ItemType Directory -Path $Destino -Force | Out-Null
Get-ChildItem -LiteralPath $base -Force | ForEach-Object {
    $target = Join-Path $Destino $_.Name
    if ($_.PSIsContainer) {
        Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force
    } else {
        Copy-Item -LiteralPath $_.FullName -Destination $target -Force
    }
}

$all = Get-ChildItem -LiteralPath $Destino -Recurse -File -Force
$total = ($all | Measure-Object -Property Length -Sum).Sum
Write-Ok ("{0} ficheros, {1:N0} MB en {2}" -f $all.Count, ($total / 1MB), $Destino)

Write-Step "Recordatorio"
Write-Host "    Copia esa carpeta como 'game' dentro de:"
Write-Host "        /switch/battleblock_theater/game"
Write-Host "    y copia el NRO en:"
Write-Host "        /switch/battleblock_theater/battleblock_theater.nro"
