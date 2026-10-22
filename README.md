# BattleBlock Theater — Nintendo Switch port

**Español** · [English](README.en.md)

Port nativo a **Nintendo Switch** de *BattleBlock Theater* (Xbox 360, XBLA)
por **recompilación estática** sobre el SDK ReXGlue: el código original en
PowerPC se traduce a C++ y se compila para AArch64. El juego corre de forma
nativa en la Switch — **sin emulador, sin intérprete**.

**Autor y créditos: DashX — Andres Arevalo**
<https://github.com/andresarevalo1>

Proyecto de fans, sin afiliación con The Behemoth ni Microsoft.

---

## Descargas

### Instalador (recomendado)

**https://andresarevalo1.github.io/battleblock-theater-nx-installer/**

Eliges tu copia de Xbox 360 (la imagen `.iso` o la carpeta ya extraída) y la
página te da un **zip listo para extraer en la microSD**, con el port, la
configuración y los archivos del juego ya colocados. Todo ocurre en tu
navegador: tus archivos del juego **no se suben a ningún sitio**.

### Descarga directa

Las compilaciones están en **[Releases](https://github.com/andresarevalo1/BattleBlockRecomp-NX/releases)**:

| Archivo | Qué es |
|---|---|
| `battleblock_theater.nro` | El port para Switch (listo para copiar a la SD) |
| `battleblock_theater.zip` | Carpeta `/switch/battleblock_theater/` completa (NRO + configuración + licencias) |
| `battleblock.toml` | Archivo de configuración (opcional, editable en la Switch) |
| `checksums.txt` | SHA-256 de todos los archivos de la release |

## Qué necesitas

- **Nintendo Switch** con custom firmware (Atmosphère + hekate).
- **sys-clk** recomendado: desbloquea las frecuencias de CPU/GPU.
- **Homebrew Menu** (hbmenu) o cualquier lanzador de `.nro` / forwarder.
- **Tu propia copia legal** de *BattleBlock Theater* (Xbox 360, XBLA, región
  World). **No se incluye nada del juego**: ni el ejecutable, ni los assets, ni
  las imágenes. Bajo tu responsabilidad. Al extraerla ocupa ~1,2 GB (el vídeo
  de la intro es 1,1 GB de eso).

## Instalación

### Opción A — el instalador web (lo más rápido)

1. Abre **https://andresarevalo1.github.io/battleblock-theater-nx-installer/**
2. Elige tu juego: la imagen `.iso` o la carpeta con `default.xex` y `GameData`.
   La página comprueba que sea la versión correcta y **crea el zip** con el port
   y tus archivos ya colocados en su sitio.
3. Extrae el zip descargado en `sdmc:/switch/`.
4. Listo: enciende la Switch con sys-clk, mantén **R** al abrir un juego para
   entrar al Homebrew Menu y arranca `battleblock_theater`.

Si ya lo tienes instalado y solo quieres la versión nueva, la misma página
tiene un botón de **actualización** que trae solo el NRO, la configuración y
las licencias (no vuelve a copiar los archivos del juego).

### Opción B — a mano

Copia el port a la microSD:

```text
/switch/battleblock_theater/battleblock_theater.nro
```

Y crea dentro la carpeta `game/` con el contenido extraído de tu XBLA:

```text
/switch/battleblock_theater/
├── battleblock_theater.nro
├── battleblock.toml          (opcional)
├── LICENSES.txt
└── game/
    ├── default.xex           <-- obligatorio, SHA-256 abajo
    ├── GameData/
    │   └── ...               (todos los datos del juego)
    ├── TitleIcon.png
    ├── Achievement01.png ... Achievement30.png
    ├── AvatarAwards/
    └── ArcadeInfo.xml, GamerPic*.png, dashboardicon.png, ...
```

Es decir: `game/` es una copia de la carpeta del XBLA extraído, tal cual.
Si te saltas `default.xex` el juego no arranca.

Puedes hacerlo a mano, o usar el script que viene en el repo: copia los
ficheros, verifica el SHA-256 del ejecutable y te dice dónde dejarlos.

```powershell
# Windows: la carpeta ya extraida, o el .iso directamente
.\tools\preparar-juego.ps1 -Xbla "D:\BattleBlock Theater (World) (XBLA)\58410A30\000D0000"
.\tools\preparar-juego.ps1 -Xbla "D:\juego.iso"
```

```sh
# Linux / macOS
./tools/preparar-juego.sh "/ruta/al/XBLA/extraido"
./tools/preparar-juego.sh "/ruta/al/juego.iso"     # necesita extract-xiso
```

Con el `.iso` como entrada, el script lo desempaqueta, busca el `default.xex`,
comprueba que sea la versión correcta y deja la carpeta `game/` lista para la
SD.

El ejecutable debe ser **exactamente** este (el port solo soporta esta
versión):

- TitleID `58410A30` — MediaID `1CF0A928` — v0.0.0.5 (2013-03-10)
- `default.xex` SHA-256:
  `87A7C33F5C039DC24796173E22D9FF0D16C5E3663B73F77CDC81FB020250979F`
- Base `0x82000000`, imagen 5.7 MB

### Arrancarlo

1. Enciende la Switch con **sys-clk** instalado.
2. Abre el **Homebrew Menu** (o tu forwarder) y elige `battleblock_theater`.
3. O lánzalo como **título del juego**: mantén **R** pulsado mientras
   arrancas. El modo applet normal **no tiene memoria suficiente** para este
   juego.

## Configuración

`battleblock.toml` va junto al `.nro` y se puede editar **en la Switch, sin
recompilar nada**.

| Clave | Por defecto | Qué hace |
|---|---|---|
| `nx_renderer` | `native` | `native` (renderer propio, rápido) o `xenos` (emulación, lento; útil para comparar) |
| `gameplay_frame_rate` | `30` | FPS del juego; súbelo a `60` si tu hardware lo aguanta |
| `menu_frame_rate` | `30` | FPS de los menús |
| `nx_min_frame_vblanks` | `2` | Espera mínima entre frames (súbelo si hay tirones) |
| `nx_msaa` | `false` | MSAA (cuesta GPU) |
| `nx_max_anisotropy` | `1` | Anisotropía de texturas |
| `nx_depth24` | `true` | Buffer de profundidad de 24 bits |
| `nx_record_thread` | `true` | Hilo de grabación de comandos |
| `nx_async_pipelines` | `true` | Compilación de pipelines en segundo plano |
| `license_mask` | `1` | `1` = copia comprada (quita el modo trial) |
| `game_language` / `user_language` | `5` | Idioma del juego y del sistema (`1` inglés, `5` español) |
| `switch_cp_core` | `2` | `2` = perfil Profi (usa los cores extra) |
| `switch_gpu_mhz` | `0` | `0` = deja los relojes al sistema (recomendado con sys-clk) |
| `log_level` | `info` | `info`, `debug`… para depurar |

## Estado

El port **funciona** en una Switch portátil con custom firmware, sys-clk y
*title override* (modo takeover):

- Arranque completo: Vulkan/NVK, swapchain 1280x720, carga del `default.xex`,
  init de audio e input.
- La **intro 3D se reproduce con sonido** y el juego corre hasta el título.
- El agotamiento de memoria del kernel durante el vídeo de la intro (el juego
  crea una textura por frame) está corregido con la evicción de texturas de
  streaming: la versión publicada es la que lleva ese fix.
- Modo applet descartado: no hay memoria suficiente, de ahí el *title
  override*.

Detalles de cada prueba en [`docs/BUILD_STATUS.md`](docs/BUILD_STATUS.md).

## Limitaciones conocidas

- **El modo applet no tiene memoria suficiente.** Usa *title override*
  (mantén **R** al arrancar) o un forwarder.
- Salida a **720p**.
- **30 FPS** de salida con la configuración por defecto; puedes probar 60 con
  `gameplay_frame_rate = 60` si tu hardware lo da.
- El juego es 2D: el renderer propio sustituye las texturas y la geometría
  originales; algunos efectos full-screen pueden verse distintos al original.
- Sin soporte de estados de guardado estilo emulador.

## Qué hay dentro

- `src/game/` — hooks, frame pacing, renderer nativo (`src/native/`), entry
  de Switch, CMake y manifests. Lo generado por el recompilador va en
  `src/game/generated/` y **no** se publica.
- `patches/` — cambios al SDK (Horizon, XMA) y al driver Vulkan.
- `release/` — `battleblock.toml` de ejemplo.
- `tools/` — toolchain files, shaders de reemplazo, comprobaciones y
  `preparar-juego.ps1` / `.sh` (preparan `game/` desde tu propia copia).
- `docs/` — `BUILD_PLAN.md` (guía de build para colaboradores) y
  `BUILD_STATUS.md` (bitácora del trabajo en hardware).
- Instalador web:
  [andresarevalo1/battleblock-theater-nx-installer](https://github.com/andresarevalo1/battleblock-theater-nx-installer).

## Créditos

**DashX — Andres Arevalo** — autor del port, del código y de este
repositorio.

<https://github.com/andresarevalo1>

## Licencia

GPL-3.0. Ver [`NOTICE`](NOTICE) para los avisos de marcas y la atribución
legal de las dependencias (obligatoria por la GPL-3.0).

*BattleBlock Theater* es marca de The Behemoth; *Nintendo Switch* es marca de
Nintendo. Proyecto de fans no oficial, sin afiliación con The Behemoth ni
Microsoft.
