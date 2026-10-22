# BattleBlock Theater — Nintendo Switch port

Port nativo a **Nintendo Switch** de *BattleBlock Theater* (Xbox 360, XBLA)
por **recompilación estática** sobre el SDK ReXGlue: el código original en
PowerPC se traduce a C++ y se compila para AArch64. El juego corre de forma
nativa en la Switch — **sin emulador, sin intérprete**.

**Autor y créditos: DashX — Andres Arevalo**
<https://github.com/andresarevalo1>

Proyecto de fans, sin afiliación con The Behemoth ni Microsoft.

---

## Descargas

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

### 1. Copia el port a la microSD

Descarga `battleblock_theater.nro` y cópialo a:

```text
/switch/battleblock_theater/battleblock_theater.nro
```

O simplemente descomprime `battleblock_theater.zip` en la raíz de la microSD:
crea la carpeta `/switch/battleblock_theater/` con el NRO dentro.

### 2. Coloca tu copia del juego

Crea la carpeta `game/` dentro de `/switch/battleblock_theater/` y copia ahí
**el contenido extraído de tu XBLA**, con esta estructura:

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
# Windows
.\tools\preparar-juego.ps1 -Xbla "D:\BattleBlock Theater (World) (XBLA)\58410A30\000D0000"
```

```sh
# Linux / macOS
./tools/preparar-juego.sh "/ruta/al/XBLA/extraido"
```

El ejecutable debe ser **exactamente** este (el port solo soporta esta
versión):

- TitleID `58410A30` — MediaID `1CF0A928` — v0.0.0.5 (2013-03-10)
- `default.xex` SHA-256:
  `87A7C33F5C039DC24796173E22D9FF0D16C5E3663B73F77CDC81FB020250979F`
- Base `0x82000000`, imagen 5.7 MB

### 3. Arráncalo

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

## Limitaciones conocidas

- **El modo applet no tiene memoria suficiente.** Usa *title override*
  (mantén **R** al arrancar) o un forwarder.
- Salida a **720p**. Probado en modo portátil; dock y juego cooperativo sin
  probar.
- **30 FPS** de salida con la configuración por defecto. Con sys-clk y CPU
  overclockeada se puede intentar `gameplay_frame_rate = 60`.
- El **vídeo de la intro** provocaba agotamiento de recursos del kernel de
  Switch (el juego crea una textura por frame). La versión publicada incluye
  un fix de evicción de texturas; **pendiente de test en hardware**.
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
