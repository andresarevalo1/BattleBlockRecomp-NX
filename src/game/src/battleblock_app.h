// battleblock - ReXGlue Recompiled Project (Switch)
// Adaptado de simpsons_app.h de the-simpsons-game-nx (R-drg, GPLv3).

#pragma once

#include <rex/rex_app.h>
#include <rex/runtime.h>
#include <rex/system/xmemory.h>
#if REX_PLATFORM_SWITCH
#include <rex/filesystem.h>
#endif
#if REX_PLATFORM_SWITCH || BATTLEBLOCK_NATIVE_RENDERER
#include <rex/runtime.h>

#include "native/native_system.h"
#endif
#if BATTLEBLOCK_NATIVE_RENDERER && !REX_PLATFORM_SWITCH
#include "dev/screenshots.h"
#include "dev/script_input.h"
#endif

namespace battleblock {
// startup_check.cpp
void LogLoadedImage(const uint8_t* base);
}  // namespace battleblock

class BattleblockApp : public rex::ReXApp {
 public:
  using rex::ReXApp::ReXApp;

  static std::unique_ptr<rex::ui::WindowedApp> Create(
      rex::ui::WindowedAppContext& ctx) {
    return std::unique_ptr<BattleblockApp>(new BattleblockApp(ctx, "battleblock",
        PPCImageConfig));
  }

#if REX_PLATFORM_SWITCH
  void OnConfigurePaths(rex::PathConfig& paths) override {
    const auto directory = rex::filesystem::GetExecutableFolder();
    if (paths.game_data_root.empty()) paths.game_data_root = directory / "game";
  }
#endif

#if REX_PLATFORM_SWITCH || BATTLEBLOCK_NATIVE_RENDERER
  // El renderer emulado 360 (EDRAM + write watching) va a pocos fps en Switch;
  // el renderer nativo dibuja el command stream con Vulkan directamente.
  void OnPreSetup(rex::RuntimeConfig& config) override {
    if (battleblock::native::Enabled()) {
      config.graphics = battleblock::native::CreateGraphicsSystem();
    }
#if BATTLEBLOCK_NATIVE_RENDERER && !REX_PLATFORM_SWITCH
    // --input_json / --input_json_file: dirige el mando 0 desde un script.
    rexglue_script_input::Install(config);
#endif
  }
#endif

  void OnPreLaunchModule() override {
    battleblock::LogLoadedImage(runtime()->memory()->virtual_membase());
#if BATTLEBLOCK_NATIVE_RENDERER && !REX_PLATFORM_SWITCH
    screenshots_.Start(runtime()->graphics_system());
#endif
  }

#if BATTLEBLOCK_NATIVE_RENDERER && !REX_PLATFORM_SWITCH
  void OnShutdown() override { screenshots_.Stop(); }
#endif

#if BATTLEBLOCK_NATIVE_RENDERER && !REX_PLATFORM_SWITCH
 private:
  battleblock::dev::Screenshots screenshots_;
#endif
};
