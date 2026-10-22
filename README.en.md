# BattleBlock Theater — Nintendo Switch port

[Español](README.md) · **English**

A native **Nintendo Switch** port of *BattleBlock Theater* (Xbox 360, XBLA) by
**static recompilation** on the ReXGlue SDK: the original PowerPC code is
translated to C++ and compiled for AArch64, so the game runs natively on the
Switch — **no emulator, no interpreter**.

**Author and credits: DashX — Andres Arevalo**
<https://github.com/andresarevalo1>

Fan project, with no affiliation to The Behemoth or Microsoft.

---

## Downloads

### Installer (recommended)

**https://andresarevalo1.github.io/battleblock-theater-nx-installer/**

Pick your own Xbox 360 copy (the `.iso` image or the already-extracted folder)
and the page gives you a **zip ready to extract into the microSD**, with the
port, the settings and the game files already in place. It all happens in your
browser: your game files **are never uploaded anywhere**.

### Direct download

The builds are in **[Releases](https://github.com/andresarevalo1/BattleBlockRecomp-NX/releases)**:

| File | What it is |
|---|---|
| `battleblock_theater.nro` | The Switch port (ready to copy to the SD card) |
| `battleblock_theater.zip` | The whole `/switch/battleblock_theater/` folder (NRO + settings + licences) |
| `battleblock.toml` | Settings file (optional, editable on the Switch) |
| `checksums.txt` | SHA-256 of every file in the release |

## What you need

- A **Nintendo Switch** with custom firmware (Atmosphère + hekate).
- **sys-clk** recommended: it unlocks the CPU/GPU clocks.
- The **Homebrew Menu** (hbmenu) or any `.nro` launcher / forwarder.
- **Your own legal copy** of *BattleBlock Theater* (Xbox 360, XBLA, World
  region). **Nothing of the game is included**: not the executable, not the
  assets, not the images. That is up to you. Extracted it takes ~1.2 GB (the
  intro video is 1.1 GB of that).

## Installation

### Option A — the web installer (fastest)

1. Open **https://andresarevalo1.github.io/battleblock-theater-nx-installer/**
2. Choose your game: the `.iso` image or the folder with `default.xex` and
   `GameData`. The page checks that it is the right version and **builds the
   zip** with the port and your files already in place.
3. Extract the downloaded zip into `sdmc:/switch/`.
4. That is it: turn the Switch on with sys-clk, hold **R** while starting a
   game to open the Homebrew Menu, and start `battleblock_theater`.

If you already have it installed and only want the new version, the same page
has an **update** button that brings just the NRO, the settings and the
licences (it does not copy the game files again).

### Option B — by hand

Copy the port to the microSD:

```text
/switch/battleblock_theater/battleblock_theater.nro
```

And create the `game/` folder inside it with the extracted contents of your
XBLA:

```text
/switch/battleblock_theater/
├── battleblock_theater.nro
├── battleblock.toml          (optional)
├── LICENSES.txt
└── game/
    ├── default.xex           <-- required, SHA-256 below
    ├── GameData/
    │   └── ...               (all the game's data)
    ├── TitleIcon.png
    ├── Achievement01.png ... Achievement30.png
    ├── AvatarAwards/
    └── ArcadeInfo.xml, GamerPic*.png, dashboardicon.png, ...
```

In other words: `game/` is a copy of the extracted XBLA folder, as it is. If
you leave out `default.xex` the game will not start.

You can do it by hand, or use the script that comes with the repository: it
copies the files, checks the SHA-256 of the executable and tells you where to
put them.

```powershell
# Windows: the already-extracted folder, or the .iso itself
.\tools\preparar-juego.ps1 -Xbla "D:\BattleBlock Theater (World) (XBLA)\58410A30\000D0000"
.\tools\preparar-juego.ps1 -Xbla "D:\game.iso"
```

```sh
# Linux / macOS
./tools/preparar-juego.sh "/path/to/extracted/XBLA"
./tools/preparar-juego.sh "/path/to/game.iso"     # needs extract-xiso
```

Given the `.iso`, the script unpacks it, looks for the `default.xex`, checks
that it is the right version and leaves the `game/` folder ready for the SD
card.

The executable must be **exactly** this one (the port only supports this
version):

- TitleID `58410A30` — MediaID `1CF0A928` — v0.0.0.5 (2013-03-10)
- `default.xex` SHA-256:
  `87A7C33F5C039DC24796173E22D9FF0D16C5E3663B73F77CDC81FB020250979F`
- Base `0x82000000`, 5.7 MB image

### Starting it

1. Turn the Switch on with **sys-clk** installed.
2. Open the **Homebrew Menu** (or your forwarder) and pick
   `battleblock_theater`.
3. Or start it as the game itself: hold **R** while launching. The normal
   applet mode **does not have enough memory** for this game.

## Settings

`battleblock.toml` goes next to the `.nro` and can be edited **on the Switch,
without recompiling anything**.

| Key | Default | What it does |
|---|---|---|
| `nx_renderer` | `native` | `native` (own renderer, fast) or `xenos` (emulation, slow; useful to compare) |
| `gameplay_frame_rate` | `30` | Game FPS; raise it to `60` if your hardware takes it |
| `menu_frame_rate` | `30` | Menu FPS |
| `nx_min_frame_vblanks` | `2` | Minimum wait between frames (raise it if there are stutters) |
| `nx_msaa` | `false` | MSAA (costs GPU) |
| `nx_max_anisotropy` | `1` | Texture anisotropy |
| `nx_depth24` | `true` | 24-bit depth buffer |
| `nx_record_thread` | `true` | Command recording thread |
| `nx_async_pipelines` | `true` | Background pipeline compilation |
| `license_mask` | `1` | `1` = bought copy (takes the trial mode off) |
| `game_language` / `user_language` | `5` | Game and system language (`1` English, `5` Spanish) |
| `switch_cp_core` | `2` | `2` = Profi profile (uses the extra cores) |
| `switch_gpu_mhz` | `0` | `0` = leave the clocks to the system (recommended with sys-clk) |
| `log_level` | `info` | `info`, `debug`… to debug |

## Status

The port **works** on a handheld Switch with custom firmware, sys-clk and a
title override (takeover mode):

- Full boot: Vulkan/NVK, 1280x720 swapchain, the `default.xex` loaded, audio
  and input up.
- The **3D intro plays with sound** and the game runs to the title screen.
- The kernel memory exhaustion during the intro video (the game creates a new
  texture per frame) is fixed with the eviction of streaming textures: this
  build carries that fix.
- Applet mode ruled out: there is not enough memory, hence the title override.

Details of every test are in [`docs/BUILD_STATUS.md`](docs/BUILD_STATUS.md).

## Known limitations

- **Applet mode does not have enough memory.** Use a title override (hold **R**
  while starting) or a forwarder.
- **720p** output.
- **30 FPS** with the default settings; you can try 60 with
  `gameplay_frame_rate = 60` if your hardware takes it.
- The game is 2D: the own renderer replaces the original textures and geometry,
  so some full-screen effects may look different from the original.
- No emulator-style save states.

## What is in here

- `src/game/` — hooks, frame pacing, native renderer (`src/native/`), Switch
  entry point, CMake and manifests. What the recompiler generates goes into
  `src/game/generated/` and is **not** published.
- `patches/` — the changes to the SDK (Horizon, XMA) and to the Vulkan driver.
- `release/` — an example `battleblock.toml`.
- `tools/` — toolchain files, replacement shaders, checks and
  `preparar-juego.ps1` / `.sh` (they prepare `game/` from your own copy).
- `docs/` — `BUILD_PLAN.md` (the build guide for contributors) and
  `BUILD_STATUS.md` (the log of the work on hardware).
- Web installer:
  [andresarevalo1/battleblock-theater-nx-installer](https://github.com/andresarevalo1/battleblock-theater-nx-installer).

## Credits

**DashX — Andres Arevalo** — author of the port, of the code and of this
repository.

<https://github.com/andresarevalo1>

## Licence

GPL-3.0. See [`NOTICE`](NOTICE) for the trademark notices and the legal
attribution of the dependencies (required by the GPL-3.0).

*BattleBlock Theater* is a trademark of The Behemoth; *Nintendo Switch* is a
trademark of Nintendo. Unofficial fan project, with no affiliation to The
Behemoth or Microsoft.
