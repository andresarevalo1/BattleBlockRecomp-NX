# BattleBlock Theater — Nintendo Switch port

Port nativo a **Nintendo Switch** de *BattleBlock Theater* (Xbox 360, XBLA)
hecho por **recompilación estática** sobre el SDK ReXGlue: el código original
en PowerPC se traduce a C++ y se compila para AArch64, de modo que el juego
corre en la Switch **sin emulador ni intérprete**.

**Autor y créditos: DashX — Andres Arevalo**
<https://github.com/andresarevalo1>

Proyecto de fans, sin afiliación con The Behemoth ni Microsoft.

> Este repositorio **no incluye contenido del juego**. Necesitas tu propia
> copia legal de *BattleBlock Theater* (XBLA) y una Switch con custom
> firmware. Bajo tu responsabilidad.

---

## Índice

- [Qué hace](#qué-hace)
- [Requisitos](#requisitos)
- [Instalación en la Switch](#instalación-en-la-switch)
- [Configuración](#configuración-battleblocktoml)
- [El juego soportado](#el-juego-soportado-gate)
- [Estado actual](#estado-actual)
- [Layout del repositorio](#layout-del-repositorio)
- [Documentación](#documentación)
- [Licencia](#licencia)

---

## Qué hace

1. Extrae el ejecutable XBLA (`default.xex`) de tu copia del juego.
2. `rexglue codegen` lo traduce de PowerPC a C++ (`src/game/generated/`,
   ignorado por git: nunca se publica).
3. Se compila con el toolchain de Switch (devkitA64) y se enlaza contra un
   driver Vulkan para Switch (Mesa/NVK) y el runtime ReXGlue.
4. Sale un `.nro` que se copia a la SD y se lanza desde el Homebrew Menu.

Resultado: el juego original corriendo en la Switch con el renderer nativo
(texturas, geometría y shaders de reemplazo propios), frame pacing a 30 FPS y
audio vía XMA2.

## Requisitos

**Para jugar:**

- Nintendo Switch con custom firmware (Atmosphère + hekate) y **sys-clk**
  (desbloquea las frecuencias de CPU/GPU).
- Homebrew Menu (hbmenu) o cualquier lanzador de `.nro`.
- Tu copia legal de *BattleBlock Theater* (Xbox 360, XBLA, región World)
  extraída en la SD (ver más abajo).
- microSD de 8 GB o superior.

**Para compilar desde el código:**

- Windows 10/11 (o Linux) con **WSL2**, **Docker Desktop** y **devkitPro**
  (paquete `switch-dev`: devkitA64 + libnx + portlibs).
- ~40 GB de disco para las compilaciones (el driver de Mesa es la parte
  pesada).
- 16 GB de RAM; con 16 GB usa `-j4` o menos en Ninja.

## Instalación en la Switch

### 1. Preparar el entorno de compilación

```sh
# devkitPro (Windows): instalar en E:\devkitPro, marcar el grupo "Switch"
#   -> E:\devkitPro\devkitA64\bin\aarch64-none-elf-gcc.exe

# WSL2 + Docker Desktop
wsl.exe --install          # en Terminal como administrador
docker --version
```

### 2. Clonar este repo y el SDK de ReXGlue

```sh
git clone https://github.com/andresarevalo1/BattleBlockRecomp-NX
cd BattleBlockRecomp-NX

# El SDK ReXGlue vive en el proyecto anfitrión TheSimpsonsGameRecomp
git clone https://github.com/YesterMester/TheSimpsonsGameRecomp base
git -C base checkout 285bea3259ce194c28f9e9ef01ff6897e4893734
```

### 3. Aplicar los parches del SDK

```sh
while read p; do
  git -C base apply --directory=tools/rexglue-sdk "$PWD/patches/rexglue-sdk/$p"
done < patches/rexglue-sdk/series
```

> Los parches de `patches/rexglue-sdk/` están escritos contra el SDK 0.8
> (Horizon: memoria, input, audio, GPU, XMA). Ver
> `docs/BUILD_STATUS.md` para el detalle de cada uno.

### 4. Compilar el driver Vulkan para Switch (Mesa/NVK)

Es el paso más pesado. Deja `lib/libvulkan.a` (+ `libnak_rs.a`): el "driver
SDK" que se enlaza en el NRO.

```sh
git clone https://github.com/danfromtico/mesa-switch mesa
git -C mesa checkout d4a00ea0ab3
for p in patches/mesa-switch/0*.patch; do git -C mesa apply "$PWD/$p"; done
cd mesa && ./build-switch-p8.sh
```

### 5. Traducir el juego (codegen)

```sh
cp src/game/battleblock_manifest.reference.toml src/game/battleblock_manifest.local.toml
# Edita el manifest local y pon la ruta de tu XBLA extraído:
#   game_root      = "C:/ruta/al/XBLA/extraido"
#   file_path      = "C:/ruta/al/XBLA/extraido/default.xex"

rexglue codegen
```

Genera `src/game/generated/default/` (134 ficheros, **ignorado por git**).
Los hints de funciones ya validados están en
`src/game/battleblock_manifest.reference.toml`.

### 6. Compilar el NRO

```sh
docker build -t battleblock-switch tools/switch

docker run --rm \
  -v "$PWD:/project" \
  -v "$PWD/base:/base" \
  -v "$PWD/driver-sdk:/mesa" \
  -w /project \
  battleblock-switch sh -c '
    cmake -S src/game -B build/switch -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_TOOLCHAIN_FILE=/project/tools/switch/toolchain.cmake \
      -DREXSDK_DIR=/base/tools/rexglue-sdk \
      -DREXGLUE_SWITCH_NVK_SDK=/mesa &&
    cmake --build build/switch -j4'
```

Sale `build/switch/battleblock.nro` (~40 MB).

### 7. Montar la carpeta de la SD

```text
/switch/battleblock_theater/
├── battleblock_theater.nro   <- build/switch/battleblock.nro, renombrado
├── battleblock.toml          <- release/battleblock.toml
├── LICENSES.txt              <- NOTICE generado con tools/make_notice.py
└── game/                     <- TU XBLA extraído
    ├── default.xex           (SHA-256 87A7C33F...979F, obligatorio)
    ├── GameData/
    ├── TitleIcon.png
    ├── Achievement*.png
    └── ...
```

`game/` es el contenido extraído de tu copia de Xbox 360. El port no lo
incluye y no puede descargarse: es material con derechos de The Behemoth.

Copia la carpeta a la **raíz de la microSD** con una herramienta que verifique
escritura (DBI por MTP, por ejemplo): un `default.xex` dañado = crash al
arrancar.

### 8. Jugar

1. Enciende la Switch con **sys-clk** instalado.
2. Abre el **Homebrew Menu** (o el lanzador de tu elección).
3. Selecciona `battleblock_theater`.
4. Si el juego no arranca, prueba en modo *takeover* (mantén **R** al
   pulsar el HOME) — da más memoria y es lo que se ha probado hasta ahora.

## Configuración (`battleblock.toml`)

El archivo va junto al `.nro` y se puede editar **en la Switch, sin
recompilar**.

| Clave | Por defecto | Qué hace |
|---|---|---|
| `nx_renderer` | `native` | `native` (propio, rápido) o `xenos` (emulación, lento, sirve para comparar) |
| `gameplay_frame_rate` | `30` | FPS del juego; sube a `60` si tu hardware lo aguanta |
| `menu_frame_rate` | `30` | FPS de los menús |
| `nx_min_frame_vblanks` | `2` | Espera mínima entre frames (sube si hay tirones) |
| `nx_msaa` | `false` | MSAA (cuesta GPU) |
| `nx_max_anisotropy` | `1` | Anisotropía de texturas |
| `nx_depth24` | `true` | Buffer de profundidad de 24 bits |
| `license_mask` | `1` | `1` = copia comprada (quita el modo trial) |
| `game_language` / `user_language` | `5` | Idioma del juego y del sistema (`1` inglés, `5` español) |
| `switch_cp_core` | `2` | Núcleo de CPU: `2` =Profi (usa los cores extra) |
| `switch_gpu_mhz` | `0` | `0` = deja los relojes al sistema (recomendado con sys-clk) |
| `log_level` | `info` | `info`, `debug`... para depurar |

## El juego soportado (gate)

- Título: *BattleBlock Theater* (XBLA, World)
- TitleID `58410A30` — MediaID `1CF0A928` — v0.0.0.5 (2013-03-10)
- `default.xex` SHA-256:
  `87A7C33F5C039DC24796173E22D9FF0D16C5E3663B73F77CDC81FB020250979F`
- Base `0x82000000`, imagen 5.7 MB. **Solo se soporta este ejecutable exacto**:
  con otro no arranca.

## Estado actual

- **PC**: validado. `battleblock.exe` (win-amd64, D3D12) bootea, crea
  pipelines, inicializa audio e input y llega al juego. Cierre limpio.
- **Switch**: compilado y empaquetado en SD. En hardware ya se ve la intro 3D
  con sonido; el último fix en curso es una fuga de memoria del kernel de
  Switch durante el vídeo de la intro (`docs/BUILD_STATUS.md`).
- Avisos no fatales conocidos: `devkit:\senoverride\...\transport.ini` (ruta
  de devkit que el juego prueba), `Bkgrd_None.baf` ausente, `#PlaylistInfo#`.

## Layout del repositorio

```text
src/game/      hooks, frame pacing, renderer nativo (src/native/), entry de
               Switch, CMake y manifests. Lo generado va en
               src/game/generated/ (ignorado por git).
patches/       cambios al SDK (Horizon/XMA) y al driver, en orden (series).
release/       battleblock.toml de ejemplo para la SD.
tools/         toolchain files, shaders de reemplazo, checks, generador de
               NOTICE.
docs/          BUILD_PLAN.md (la guía de build) y BUILD_STATUS.md (bitácora).
```

## Documentación

- [`docs/BUILD_PLAN.md`](docs/BUILD_PLAN.md) — plan de build paso a paso.
- [`docs/BUILD_STATUS.md`](docs/BUILD_STATUS.md) — bitácora del trabajo en
  hardware: qué se probó, qué falló y qué se arregló.
- `tools/check_no_game_content.sh` — comprueba que no se cuela contenido del
  juego en el repo.
- `tools/make_notice.py` — genera el `LICENSES.txt` que va en la SD.

## Licencia

GPL-3.0. Sin afiliación con The Behemoth ni Microsoft. Necesitas tu copia
legal del juego y una Switch con custom firmware (bajo tu responsabilidad).

*BattleBlock Theater* es marca de The Behemoth; *Nintendo Switch* es marca de
Nintendo. Ver [`NOTICE`](NOTICE) para los avisos de marcas y las licencias de
las dependencias.
