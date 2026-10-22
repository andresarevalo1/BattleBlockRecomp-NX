#!/usr/bin/env bash
# Prepara la carpeta game/ de la SD a partir de TU copia extraida del XBLA.
#
#   ./tools/preparar-juego.sh "/ruta/al/XBLA/extraido" [destino]
#
# El port NO incluye el contenido del juego (material con derechos de The
# Behemoth): cada uno usa su propia copia. Este script copia y verifica la
# tuya, y comprueba que sea la version que el port soporta.

set -euo pipefail

XEX_SHA256="87A7C33F5C039DC24796173E22D9FF0D16C5E3663B73F77CDC81FB020250979F"

XBLA="${1:-}"
DESTINO="${2:-./game}"

if [ -z "$XBLA" ]; then
    echo "uso: $0 <carpeta-del-XBLA-extraido> [destino]" >&2
    exit 1
fi

if [ ! -d "$XBLA" ]; then
    echo "[x] no existe la ruta: $XBLA" >&2
    echo "    debe ser la carpeta con 'default.xex' y 'GameData/'" >&2
    exit 1
fi

if [ ! -f "$XBLA/default.xex" ]; then
    echo "[x] no hay 'default.xex' en $XBLA" >&2
    echo "    no es el XBLA extraido" >&2
    exit 1
fi

echo "==> comprobando el ejecutable"
if command -v sha256sum >/dev/null 2>&1; then
    hash=$(sha256sum "$XBLA/default.xex" | cut -d' ' -f1)
else
    hash=$(shasum -a 256 "$XBLA/default.xex" | cut -d' ' -f1)
fi
# Solo los digitos hexadecimales: sha256sum imprime "hash *ruta" y la ruta
# puede traer barras invertidas de Windows.
hash=$(printf '%s' "$hash" | tr -cd '0-9a-fA-F' | tr 'a-f' 'A-F')

if [ "$hash" != "$XEX_SHA256" ]; then
    echo "[x] SHA-256 distinto al esperado" >&2
    echo "    esperado: $XEX_SHA256" >&2
    echo "    obtenido: $hash" >&2
    echo "    este port solo soporta TitleID 58410A30 / MediaID 1CF0A928 / v0.0.0.5" >&2
    exit 1
fi
echo "    [ok] default.xex verificado (SHA-256 correcto)"

if [ ! -d "$XBLA/GameData" ]; then
    echo "[x] no hay 'GameData/' en $XBLA" >&2
    exit 1
fi

echo "==> copiando a $DESTINO"
mkdir -p "$DESTINO"
cp -a "$XBLA"/. "$DESTINO"/

total=$(du -sh "$DESTINO" | cut -f1)
echo "    [ok] $total en $DESTINO"

echo "==> recordatorio"
echo "    copia esa carpeta como 'game' dentro de:"
echo "        /switch/battleblock_theater/game"
echo "    y el NRO en:"
echo "        /switch/battleblock_theater/battleblock_theater.nro"
