# BattleBlock Theater — Nintendo Switch port (proyecto)

Port a Nintendo Switch por **dashx**: port nativo de la versión Xbox 360
(XBLA) por recompilación estática, siguiendo el diseño de
`the-simpsons-game-nx` (R-drg) y `project8-sw`, sobre el SDK ReXGlue.
Proyecto de fans sin afiliación con The Behemoth ni Microsoft.

**Autor y créditos: DashX — Andres Arevalo**
(<https://github.com/andresarevalo1>)

Estado: PC validado. Switch: esqueleto + plan. Sin contenido del juego:
este repo no incluye `default.xex`, assets, ni el código generado.

## El juego soportado (gate)

- Título: BattleBlock Theater (XBLA, World)
- TitleID: `58410A30` — MediaID: `1CF0A928` — v0.0.0.5 (2013-03-10)
- `default.xex` SHA-256:
  `87A7C33F5C039DC24796173E22D9FF0D16C5E3663B73F77CDC81FB020250979F`
- Base `0x82000000`, imagen 5.7 MB. Solo se soporta este ejecutable exacto.

## Lo ya probado (PC, ReXGlue v0.10.0)

- `rexglue codegen` pasa con 6 hints `[entrypoint.functions]`
  (ver `src/game/battleblock_manifest.reference.toml`).
- `battleblock.exe` (win-amd64, D3D12 + `rexgpu-xenos`) bootea, crea
  pipelines, inicializa audio/input y llega al juego. Cierre limpio.
- Avisos no fatales: `devkit:\senoverride\...\transport.ini` (ruta de
  devkit que el juego prueba), `Bkgrd_None.baf` ausente, `#PlaylistInfo#`.

## Layout (igual que the-simpsons-game-nx)

```text
src/game/      hooks, frame pacing, renderer nativo (src/native/), entry Switch,
               CMake, manifests. Lo generado va en src/game/generated/ (ignorado).
patches/       cambios al SDK (Horizon) y al driver, en orden (series).
release/       battleblock.toml de ejemplo para la SD.
tools/         toolchain files, shaders de reemplazo, checks.
docs/          BUILD_PLAN.md es la guía.
```

## Créditos

**DashX — Andres Arevalo** — autor del port y de todo el trabajo de este
repositorio.

<https://github.com/andresarevalo1>

## Agradecimientos

Este proyecto se apoya en el trabajo de otras personas. Sin ellas no
existiría:

- **[R-drg](https://github.com/R-drg)** — `the-simpsons-game-nx` y
  `project8-sw`: el diseño del port a Switch que este proyecto sigue.
- **[YesterMester](https://github.com/YesterMester)** — *The Simpsons Game
  Recompiled*: el runtime ReXGlue sobre el que está construido el port.
- **[sp00nz](https://github.com/sp00nznet/360tools)** — `360tools`: el kit de
  herramientas de recompilación que se usa para el análisis.
- **devkitPro** — toolchain de Switch (devkitA64, libnx) y portlibs.

Los parches incluidos en `patches/` son ports de los proyectos anteriores y
conservan sus licencias originales (ver `LICENSES/`).

## Licencia

GPL-3.0, como TheSimpsonsGameRecomp y el código que adapta de
nfsmw-nx/project8-sw/the-simpsons-game-nx. Sin afiliación con The Behemoth
ni Microsoft. Necesitas tu copia legal del juego y una Switch con
custom firmware (bajo tu responsabilidad).
