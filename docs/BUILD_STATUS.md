# BattleBlock Theater Switch — estado del trabajo (2026-10-05)

## Veredicto versión a portear
- **Sí: Xbox 360 XBLA** (`D:\BattleBlock Theater (World) (XBLA)\58410A30\000D0000`,
  `default.xex` + `GameData/`). TitleID `58410A30`, MediaID `1CF0A928`, v0.0.0.5.
- **No: PC** (`D:\BattleBlloc-PiviGames.blog\...\Data\BattleBlockTheater.exe`,
  x86 + Steam/SmartSteamEmu). Sin fuente, no recompilable a ARM/Horizon.

## Toolchain (verificado hoy)
- `C:\devkitPro\devkitA64\bin\aarch64-none-elf-gcc.exe` OK (el LEEME pedía
  `E:\devkitPro`; con C: basta, ajustar rutas).
- Docker 29.8.2 OK, contexto desktop-linux. Contenedor `mesa-switch-build`
  (imagen `devkitpro-mesa-rust-aarch64`) corriendo, `/project` = checkout mesa.
- WSL: `wsl -d Ubuntu -- echo` OK (distro Ubuntu v2). El aviso de
  `wsl --status` sobre WSL1 es cosmético mientras Docker Desktop use el motor
  WSL2; no bloquea.

## Codegen (revalidado hoy)
- `bbt-recomp\rexglue-sdk\win-amd64\bin\rexglue.exe` v0.10.0.
- `rexglue codegen` en `bbt-recomp\battleblock`: **pasa** —
  `Title ID: 58410A30, Media ID: 1CF0A928, Version: 0.0.0.5`,
  `1 module(s) up to date`. Hints ya conocidos en
  `src/game/battleblock_manifest.reference.toml` (7 direcciones).

## Hallazgo SDK (importante)
- `patches/rexglue-sdk/0001-switch-port.patch` (510 KB, SDK 0.8.0) **NO aplica**
  sobre `base/tools/rexglue-sdk` (checkout `285bea32`): ~20 rechazos y varios
  `already exists in working directory`.
- Causa: ese SDK **ya trae el soporte Switch integrado**
  (`cmake/rexglue_switch.cmake` existe). El forward-port 0.8→0.10 es
  **innecesario**; el parche queda como referencia histórica en
  `patches/rexglue-sdk/` (`0001-...patch` + `series` + `README.ref.md`).
- `REXSDK_DIR` para el NRO = `E:\BattleBlockRecomp\base\tools\rexglue-sdk` tal cual.

## Esqueleto `battleblock-nx` poblado hoy
- `src/game/CMakeLists.txt` (adaptado del proyecto de referencia) +
  `CMakeLists.txt.ref`
- `src/game/cmake/switch.cmake` (adaptado) + `switch.cmake.ref` +
  `cmake/embed_native_shaders.py`
- `src/game/CMakePresets.json`
- `src/game/src/`: `main.cpp`, `battleblock_app.h`, `frame_pacing.cpp`,
  `ring_wait.cpp`, `draw_telemetry.cpp`, `subtitles.cpp`, `startup_check.cpp`,
  `guest_pacing_stats.h`, `native/*` (9 ficheros), `dev/*` (2).
  Namespaces/macros renombrados a `battleblock::` / `BATTLEBLOCK_`.
- `src/game/compat_switch/`, `src/game/compat_win/`
- `src/game/switch/icon.jpg` (placeholder copiado de un proyecto de
  referencia; **reemplazar** por arte propio antes de publicar) +
  `icon.placeholder.jpg`
- `src/game/generated/` (134 ficheros, copiados de
  `bbt-recomp/battleblock/generated`; ignorados por git). Regenerar con
  `rexglue codegen` si cambia el manifest.
- `tools/switch/` (Dockerfile, toolchain.cmake, stage-mesa-archive.py)
- `tools/native-renderer/native_shaders` (de referencia; BattleBlock 2D
  probablemente necesite pocos shaders de reemplazo),
  `tools/check_no_game_content.sh`, `tools/make_notice.py`
- `patches/mesa-switch/` (4 parches + README.ref.md, ya aplicados al checkout
  `E:\BattleBlockRecomp\mesa` según `BUILD_PLAN.md`)

## Driver Mesa NVK (en curso)
- `E:\BattleBlockRecomp\mesa\builddir-switch` ya configurado, a medias.
- Fallo encontrado hoy: `rustc E0463 can't find crate for std` (faltaba el
  target). **Arreglado**: `rustup target add aarch64-unknown-linux-gnu`.
- Rebuild lanzado en el contenedor (`ninja -j4`, log
  `/tmp/mesa-switch-bbt2.log`): progresaba `[136/1083]` al arrancar.
- Al terminar debe producir `libvulkan.a` (+ `libnak_rs.a`): el "driver SDK".

## Siguiente paso (cuando acabe Mesa)
```sh
docker build -t battleblock-switch tools/switch
docker run --rm -v "$PWD:/project" -v /path/to/base:/base \
  -v /path/to/driver-sdk:/mesa -w /project battleblock-switch sh -c '
  cmake -S src/game -B build/switch -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=/project/tools/switch/toolchain.cmake \
    -DREXSDK_DIR=/base/tools/rexglue-sdk -DREXGLUE_SWITCH_NVK_SDK=/mesa &&
  cmake --build build/switch -j4'
```
Sale `build/switch/battleblock.nro`. SD:
`/switch/battleblock_theater/` = NRO renombrado + `battleblock.toml`
(`release/`) + `LICENSES.txt` (`tools/make_notice.py`) + `game/` (tu XBLA).

## NRO compilado (2026-10-05, EXIT:0)
- Bloqueo encontrado: `battleblock_init.cpp` 0.10 usa `.codegen_flags`
  (ausente en SDK 0.8). Solución: codegen rehecho con ReXGlue
  `0.8.0.1-dev.g285bea32` (tool ya compilado en
  `base/tools/rexglue-sdk/out/win-amd64/Release/rexglue.exe`) en
  `E:\BattleBlockRecomp\bbt08\` — pasa limpio en 4.8 s con los mismos 8 hints
  (ahora en `src/game/functions_patch.toml`, manifest en esquema 0.8).
- Fallos menores corregidos: `src/native/shaders/*.h` copiados de referencia;
  tabla vacía de replacement shaders generada con `embed_native_shaders.py`
  adaptado a `battleblock::native` (los `.frag` de referencia, de otro juego,
  apartados a `tools/native-renderer/native_shaders/reference-shaders/`).
- `build/switch/battleblock.nro` = **41 MB** (+ `battleblock` 59 MB sin strip
  para `addr2line`, `.nacp`, `.stripped.elf`). Warnings solo de SDK
  (`-Wunused-parameter`, `-Wattributes` en PCH).
- Driver SDK usado: `E:\BattleBlockRecomp\driver-sdk\lib\`
  (`libvulkan.a` 99.9 MB fusionado y validado: 1734 objetos AArch64 +
  `libnak_rs.a` 33.7 MB al lado).

## Paquete SD (2026-10-05, verificado)
`E:\BattleBlockRecomp\sd\switch\battleblock_theater\`:
- `battleblock_theater.nro` (41 MB, renombrado), `battleblock.toml`,
  `LICENSES.txt` (291 KB, `tools/make_notice.py` adaptado a BattleBlock +
  `LICENSE` GPL-3.0 y `LICENSES/switch/` copiados de referencia),
  `game/` = XBLA extraído completo (1 235 138 964 bytes, idéntico al origen;
  `default.xex` SHA-256 `87A7C33F...979F` = gate).
- Copiar a la SD con herramienta que verifique (DBI por MTP).

## Test 1 en hardware (2026-10-05): crash por memoria + icono placeholder
- Síntomas: icono placeholder (ya sustituido por TitleIcon del
  XBLA a 256x256 JPEG) y cierre con "se ha cerrado el programa", negro desde
  el inicio, sin código de error.
- Logs del usuario (`Downloads/logs`, 5 arranques): el arranque 001 llega a
  Vulkan/NVK, swapchain 1280x720, carga del XEX e init de audio; luego
  `XmaContext 276..319: Couldn't allocate context`, `AllocFixed: no se pudo
  confirmar` (respaldo 16 MB) y `std::bad_alloc` → terminate (`rex_crash.log`).
  Los arranques 002-005 se quedan en "Switch: in focus" (116 líneas, 0 errores:
  cerrados a mano en pantalla negra).
- Causa: el SDK precrea los 320 contextos XMA en `AudioSystem::Setup`, cada
  uno con `av_buffer_alloc(128 KB)` inútil (`PreparePacket` siempre envuelve
  `xma_frame_` propio) = 40 MB de heap host desperdiciados en cada arranque,
  que inclinan el heap de 1 GB (`__nx_heap_size`) al fallo durante la intro.
- Fix: `patches/rexglue-sdk/0002-xma-no-prealloc-packet-buffer.patch`
  (aplicado en `base/tools/rexglue-sdk`), NRO en reconstrucción.
- Nota renderer: el comentario "stage A" en `native_system.cpp` es obsoleto;
  el renderer nativo es completo (texturas, geometría, replacements) como en
  el port de referencia. La pantalla negra corresponde a pantallas de carga
  oscuras + crash antes del primer frame del juego.
1. Probar en Switch con CFW + Homebrew en modo takeover + sys-clk.
   Todo es "no verificado en hardware" hasta jugar.
2. `src/game/switch/icon.jpg` es placeholder (copiado de un proyecto de
   referencia): reemplazar por arte propio antes de publicar.
3. Medir GPU (`nx_gpu_profile`), escribir replacement shaders si algún
   full-screen pesa, ajustar frame pacing 30→60 si el hardware lo da.
4. Hooks `BattleblockApp`: vídeos `.wmv`, audio `.xma2`,
   `XamShowMarketplaceUI` stub; `docs/known-issues.md`.
1. Renderer nativo: medir; escribir replacement shaders solo para los
   full-screen más caros (pocos en 2D).
2. Hooks `BattleblockApp`: rutas `game:\GameData\...`, vídeos `.wmv` (FFmpeg),
   audio `.xma2`, stub `XamShowMarketplaceUI` (ya visto como no-op en PC).
3. Frame pacing 30 (probar 60 si el hardware lo da).
4. `icon.jpg` propio, `docs/known-issues.md`, probar en hardware con sys-clk
   y Homebrew en modo takeover. Todo es "no verificado en hardware" hasta jugar.

## Test 2 en hardware (2026-10-05): sin OOM, crash en nuestro startup_check
- El fix XMA funcionó: 320 contextos OK, sin `Couldn't allocate`, sin `bad_alloc`.
- Nuevo crash: `fallo de acceso a memoria` en `LogImage` (startup_check.cpp),
  simbolizado con addr2line (pc imagen+0x451598): leía `base+0x82000000..0x82EC0000`
  + list head `0x82CD272C`, direcciones del XEX de referencia; la imagen de
  BattleBlock acaba
  en `0x825B0000` y en Switch leer guest no confirmado desde el host falla
  (guest 0x82cb0000 = host 0x0f2fe75000, región sin mapear).
- Fix: rangos a imagen real (`kImageEnd=0x825B0000`, datos `0x824DC578..fin`),
  sin list head. NRO reconstruido (host + link, EXIT:0) y reempaquetado en SD.
- Siguiente: pasar el arranque real del juego (constructores, vídeo intro, menú).

## Test 3 en hardware (2026-10-05): media intro visible, luego data abort
- La intro 3D SE VE en movimiento (render + audio OK) y cae a la mitad.
- Crash: data abort en `sub_82472390` (= memmove del juego) escribiendo en
  heap guest; antes falla `AllocFixed: no se pudo confirmar 0x4000 bytes ...
  Fallo 0x0000CE01` con respaldo 166 MB / mapeado 148 MB (lejos de agotar el
  heap de 1 GB). 0xCE01 = slab allocator del kernel agotado / recurso agotado
  (KMemoryBlock slab): miles de mapeos pequeños con fuga (texturas/mappings
  por frame del vídeo sin liberar) encajan con muerte en ~10 s de intro.
- Takeover (R) confirmado por el usuario: no es modo applet (400 MB).
- Aislamiento pendiente SIN recompilar (solo editar `battleblock.toml` en SD):
  A) `nx_renderer = "xenos"` (lento, 2-8 fps): si pasa la intro, la fuga está
  en el renderer nativo; si cae igual, es núcleo/memoria.
  B) Si A cae igual: de vuelta a `"native"` + `nx_texture_fast_path = false`.

## Test 4 en hardware (2026-10-05): xenos cae en el MISMO punto- `nx_renderer = "xenos"`: tarda más (~56 s, emulación lenta) pero muere en el
  mismo punto de la intro: `AllocFixed 0x4000 ... Fallo 0x0000CE01`
  (respaldo 161 MB / mapeado 142 MB) → write fault. NO es el renderer nativo.
- Descartado modo applet (takeover confirmado). El fallo es común a ambos
  renderers: memoria guest/commit o recurso compartido (Vulkan/driver).
- En curso: build PC Windows 0.8 (`out/build/win-amd64-release`, D3D12) para
  comparar la curva de crecimiento de memoria guest con heap ilimitado y
  cazar la fuga en caliente. Lanzar:
  `battleblock.exe --game_data_root=E:\BattleBlockRecomp\bbt-recomp\extracted ...`

## Test 5-6 en hardware (2026-10-05): Video_OFF pasa el crash, cuelga en logo
- Con `GameData/Video` renombrada a `Video_OFF`: sin errores AllocFixed, el
  juego pasa el punto de muerte y se congela en el logo XBLA (pantalla
  quieta). Como la carpeta de vídeos falta, el culpable del crash es el path
  de texturas de vídeo por frame; el cuelgue con vídeos ausentes es un
  artefacto del test (textura ausente → GPU) y no se persigue.
- PC (battleblock08 0.10, D3D12): llega al título estable (816 MB, 3 draws/
  frame). Sin fuga en el juego; el muro es del port Switch.
- Conclusión: el vídeo crea una textura nueva por frame; la evicción a 600
  frames (20 s) nunca llega antes de la muerte (~10 s). Cada textura viva
  cuesta mapeos de kernel (imagen, memoria, vistas, staging) y el slab se
  agota (0xCE01) con bytes modestos (~166 MB).

## Fix evicción (2026-10-05, NRO en SD)
- `src/native/native_textures.cpp`: `kEvictFrames` 600 → 120 (~2 s @60).
  Texturas de streaming (vídeo) se liberan; las reutilizadas cada frame
  (UI, niveles) nunca se evictan. Rebuild host+link EXIT:0, NRO 40.99 MB
  reempaquetado en `sd/` (misma talla, timestamp nuevo).
- Probar con vídeos ORIGINALES (carpeta `Video`) + renderer native.
