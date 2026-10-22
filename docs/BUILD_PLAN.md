# Plan de build Switch

Los pasos, en orden: SDK + parches Horizon, driver Vulkan (NVK/Mesa),
traducción del juego, NRO, SD. Todo lo pesado corre en Linux/Docker;
esta máquina (Win, 16 GB RAM, Ryzen 3400G) puede hacerlo con jobs bajos,
pero necesita WSL2 + Docker Desktop + devkitA64 primero.

## 0. Requisitos en esta máquina (pendiente)

1. Ejecutar `devkitProUpdater-3.0.3.exe` COMO ADMINISTRADOR
   (está en Temp; requiere elevación UAC) → instalar en `E:\devkitPro`,
   paquete `switch-dev`. Alternativa: todo dentro de Docker (paso 1).
2. Instalar WSL2 (`wsl.exe --install`) y Docker Desktop.
3. sys-clk en la Switch + Homebrew Menu en modo takeover (R al lanzar).
   El objetivo es 30 FPS con OC (CPU 1785 / GPU 768) como referencia;
   BattleBlock es 2D y puede pedir menos — verificar en hardware.

Comprobado que FALTA: devkitA64, Docker, WSL2. Comprobado que HAY:
git, CMake 4.4, Ninja, LLVM/Clang 23, VS2022 (solo sirvió para el PC).

## 1. SDK + parches Horizon

```sh
git clone https://github.com/YesterMester/TheSimpsonsGameRecomp base
git -C base checkout 285bea3259ce194c28f9e9ef01ff6897e4893734
while read p; do git -C base apply --directory=tools/rexglue-sdk "$PWD/patches/rexglue-sdk/$p"; done < patches/rexglue-sdk/series
```

ATENCIÓN: esos parches son contra SDK 0.8 y nuestro PC usa SDK 0.10.0.
Hay que forward-portear `0001-switch-port.patch` (Horizon: runtime,
memoria, input, audio, crash handling, GPU) a 0.10.0 o fijar SDK 0.8
para Switch. Decisión pendiente tras leer el patch.

## 2. Driver gráfico (NVK/Mesa en la NRO)

```sh
git clone https://github.com/danfromtico/mesa-switch mesa
git -C mesa checkout d4a00ea0ab3
for p in patches/mesa-switch/0*.patch; do git -C mesa apply "$PWD/$p"; done
cd mesa && ./build-switch-p8.sh
```

Deja `lib/libvulkan.a` (+ `libnak_rs.a`): el "driver SDK".
Es el paso más pesado. Reutilizable tal cual entre juegos.

## 3. Traducir BattleBlock

```sh
cp src/game/battleblock_manifest.reference.toml src/game/battleblock_manifest.local.toml
# Edita el manifest local y pon la ruta de tu XBLA extraído:
#   game_root = "C:/ruta/al/XBLA/extraido"
#   file_path = "C:/ruta/al/XBLA/extraido/default.xex"
rexglue codegen
```

Escribe `src/game/generated/default/` (ignorado por git, jamás publicar).
Los 6 hints ya conocidos están en el `.reference.toml`.

## 4. NRO (en Docker, imagen devkitA64 + clang 19 + glslang)

```sh
docker build -t battleblock-switch tools/switch
docker run --rm -v "$PWD:/project" -v /path/to/base:/base -v /path/to/driver-sdk:/mesa -w /project \
  battleblock-switch sh -c '
    cmake -S src/game -B build/switch -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_TOOLCHAIN_FILE=/project/tools/switch/toolchain.cmake \
      -DREXSDK_DIR=/base/tools/rexglue-sdk -DREXGLUE_SWITCH_NVK_SDK=/mesa &&
    cmake --build build/switch -j4'
```

Sale `build/switch/battleblock.nro`. Con 16 GB RAM usar `-j4` o menos
(cada TU traducida puede pedir ~3 GB en GCC).

## 5. SD

```text
/switch/battleblock_theater/
  battleblock_theater.nro   build/switch/battleblock.nro, renombrado
  battleblock.toml          release/battleblock.toml
  LICENSES.txt              NOTICE (tools/make_notice.py)
  game/                     tu XBLA extraído: default.xex + GameData/ + PNGs
```

Copiar con herramienta que verifique (DBI por MTP): un `default.xex`
dañado en la SD = crash al arrancar.

## Trabajo específico del juego (lo que hace distinto a cada port)

1. Renderer nativo: `src/native/` ya está escrito; escribir replacement
   shaders solo para los efectos full-screen más caros
   (BattleBlock 2D: probablemente pocos).
2. Hooks/ReXApp: rutas `game:\GameData\...`, videos `.wmv` (FFmpeg),
   audio `.xma2`, `XamShowMarketplaceUI` (stub no-op ya visto en PC).
3. Frame pacing a 30 (o 60 si el hardware lo da — medir).
4. `docs/known-issues.md`: todo es "no verificado en hardware" hasta
   jugarlo en Switch.
