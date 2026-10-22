#!/usr/bin/env bash
# Prepara la carpeta game/ de la SD a partir de TU copia del XBLA.
#
#   ./tools/preparar-juego.sh "/ruta/al/XBLA/extraido" [destino]
#   ./tools/preparar-juego.sh "/ruta/al/juego.iso" [destino]
#
# Acepta la carpeta ya extraida o el .iso / .xiso del XBLA (si tienes
# extract-xiso instalado, el .iso se desempaqueta solo).
#
# El port NO incluye el contenido del juego (material con derechos de The
# Behemoth): cada uno usa su propia copia. Este script copia y verifica la
# tuya, y comprueba que sea la version que el port soporta.

set -euo pipefail

XEX_SHA256="87A7C33F5C039DC24796173E22D9FF0D16C5E3663B73F77CDC81FB020250979F"

ORIGEN="${1:-}"
DESTINO="${2:-./game}"

if [ -z "$ORIGEN" ]; then
    echo "uso: $0 <carpeta-del-XBLA-o-iso> [destino]" >&2
    exit 1
fi

if [ ! -e "$ORIGEN" ]; then
    echo "[x] no existe: $ORIGEN" >&2
    exit 1
fi

# --- 1. Si es un .iso/.xiso, desempaquetarlo --------------------------------
EXTRAIDO="$ORIGEN"
if [ -f "$ORIGEN" ]; then
    case "$ORIGEN" in
        *.iso|*.ISO|*.xiso|*.XISO)
            if command -v extract-xiso >/dev/null 2>&1; then
                EXTRAIDO="$(mktemp -d)/xiso"
                mkdir -p "$EXTRAIDO"
                echo "==> desempaquetando el ISO (extract-xiso)"
                extract-xiso -i "$ORIGEN" "$EXTRAIDO" >/dev/null 2>&1 || \
                    extract-xiso "$ORIGEN" "$EXTRAIDO" >/dev/null
                echo "    [ok] ISO desempaquetado en $EXTRAIDO"
            else
                echo "[x] '$ORIGEN' es un ISO pero no esta 'extract-xiso'." >&2
                echo "    Instala Xbox-ISO-Lib (extract-xiso) o extrae el ISO" >&2
                echo "    a mano y pasa la carpeta resultante a este script." >&2
                exit 1
            fi
            ;;
        *)
            echo "[x] el fichero '$ORIGEN' no es un ISO." >&2
            exit 1
            ;;
    esac
fi

# --- 2. Localizar default.xex ----------------------------------------------
XEX=""
if [ -f "$EXTRAIDO/default.xex" ]; then
    XEX="$EXTRAIDO/default.xex"
    BASE="$EXTRAIDO"
else
    # Buscar en subdirectorios (el XBLA suele venir en TitleID/MediaID/...).
    found=$(find "$EXTRAIDO" -type f -iname 'default.xex' 2>/dev/null | head -n 1)
    if [ -n "$found" ]; then
        XEX="$found"
        BASE="$(dirname "$found")"
        echo "==> default.xex encontrado en $BASE"
    fi
fi

if [ -z "$XEX" ]; then
    echo "[x] no hay 'default.xex' en '$EXTRAIDO'" >&2
    echo "    el ISO no es del XBLA de BattleBlock Theater, o no esta" >&2
    echo "    desempaquetado con extract-xiso." >&2
    exit 1
fi

# --- 3. Verificar el ejecutable ---------------------------------------------
echo "==> comprobando el ejecutable"
if command -v sha256sum >/dev/null 2>&1; then
    hash=$(sha256sum "$XEX" | cut -d' ' -f1)
else
    hash=$(shasum -a 256 "$XEX" | cut -d' ' -f1)
fi
# Solo digitos hexadecimales: sha256sum imprime "hash *ruta" y la ruta puede
# traer barras invertidas de Windows.
hash=$(printf '%s' "$hash" | tr -cd '0-9a-fA-F' | tr 'a-f' 'A-F')

if [ "$hash" != "$XEX_SHA256" ]; then
    echo "[x] SHA-256 distinto al esperado" >&2
    echo "    esperado: $XEX_SHA256" >&2
    echo "    obtenido: $hash" >&2
    echo "    este port solo soporta TitleID 58410A30 / MediaID 1CF0A928 / v0.0.0.5" >&2
    exit 1
fi
echo "    [ok] default.xex verificado (SHA-256 correcto)"

if [ ! -d "$BASE/GameData" ]; then
    echo "[x] no hay 'GameData/' junto al default.xex" >&2
    exit 1
fi

# --- 4. Copiar --------------------------------------------------------------
echo "==> copiando a $DESTINO"
mkdir -p "$DESTINO"
cp -a "$BASE"/. "$DESTINO"/

total=$(du -sh "$DESTINO" | cut -f1)
echo "    [ok] $total en $DESTINO"

echo "==> recordatorio"
echo "    copia esa carpeta como 'game' dentro de:"
echo "        /switch/battleblock_theater/game"
echo "    y el NRO en:"
echo "        /switch/battleblock_theater/battleblock_theater.nro"
