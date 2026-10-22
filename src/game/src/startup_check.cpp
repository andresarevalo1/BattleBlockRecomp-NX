// Startup image check.
//
// BattleBlock Theater XBLA: code=82170000-824DC578, image=82000000-825B0000
// (ver "Function table initialized for module" en el log). Solo se lee dentro
// de la imagen cargada: en Switch la RAM del invitado se confirma por toques
// (chunks de 4 MB) y leer más allá del final de la imagen desde el host
// provoca un fallo de acceso en vez de devolver ceros como en PC.
// Dos líneas de log por arranque.

#include <cstdint>
#include <cstring>

#include <rex/logging.h>
#include <rex/ppc.h>

namespace {

constexpr uint32_t kImageStart = 0x82000000;
constexpr uint32_t kImageEnd = 0x825B0000;  // fin de imagen de BattleBlock

uint64_t Fnv1a(const uint8_t* data, size_t size) {
  uint64_t hash = 0xCBF29CE484222325ull;
  for (size_t i = 0; i < size; ++i) {
    hash = (hash ^ data[i]) * 0x100000001B3ull;
  }
  return hash;
}

void LogImage(const char* when, const uint8_t* base) {
  // Solo la imagen cargada: el código nunca se lee de la memoria del invitado
  // más allá de su final. Datos ~= fin de código..fin de imagen.
  constexpr uint32_t kDataStart = 0x824DC578;
  REXLOG_INFO("startup check ({}): image hash {:016X}, data hash {:016X}", when,
              Fnv1a(base + kImageStart, kImageEnd - kImageStart),
              Fnv1a(base + kDataStart, kImageEnd - kDataStart));
}

}  // namespace

namespace battleblock {

void LogLoadedImage(const uint8_t* base) {
  LogImage("loaded", base);
}

}  // namespace battleblock

// Passthrough con log: registra el hash cuando el juego pasa por sub_82433FD0
// por primera vez y luego llama al original sin cambiar nada.
REX_EXTERN(__imp__sub_82433FD0);
REX_EXTERN(sub_82433FD0);

REX_FUNC(sub_82433FD0) {
  static bool logged = false;
  if (!logged) {
    logged = true;
    LogImage("first list walk", base);
  }
  __imp__sub_82433FD0(ctx, base);
}
