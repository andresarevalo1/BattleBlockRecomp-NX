# Soporte para Switch (Horizon). La generacion de codigo se queda en el host.
# SPDX-License-Identifier: GPL-3.0-or-later - ver NOTICE en la raiz del repo.
# REXSDK_DIR is the ReXGlue SDK with patches/rexglue-sdk applied (docs/BUILD_PLAN.md).
set(REXSDK_DIR "" CACHE PATH "Switch SDK source (patched)")
if(NOT EXISTS "${REXSDK_DIR}/cmake/rexglue_switch.cmake")
    message(FATAL_ERROR "Set REXSDK_DIR to the patched SDK (see docs/BUILD_PLAN.md)")
endif()
set(BATTLEBLOCK_GENERATED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/generated/default" CACHE PATH "Generated game sources")
if(NOT EXISTS "${BATTLEBLOCK_GENERATED_DIR}/sources.cmake")
    message(FATAL_ERROR "Generate the BattleBlock translation units before cross-compiling (rexglue codegen)")
endif()
add_subdirectory("${REXSDK_DIR}" rexglue-sdk)
include("${BATTLEBLOCK_GENERATED_DIR}/sources.cmake")
add_library(battleblock_recomp OBJECT ${GENERATED_SOURCES})
target_include_directories(battleblock_recomp PRIVATE "${BATTLEBLOCK_GENERATED_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/compat_switch")
target_link_libraries(battleblock_recomp PRIVATE rex::runtime)
target_compile_options(battleblock_recomp PRIVATE -O3 -ffp-contract=off
    -fno-tree-slp-vectorize -fno-tree-vectorize)

# Native replacement shaders (full-screen post effects) compilados y embebidos
# en el NRO. En BattleBlock 2D probablemente pocos; de momento se reutiliza el
# pipeline de shaders ya probado. Si no hay .frag, se genera un cpp vacio.
set(BATTLEBLOCK_NATIVE_SHADER_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/../../tools/native-renderer/native_shaders")
file(GLOB BATTLEBLOCK_NATIVE_SHADER_FILES "${BATTLEBLOCK_NATIVE_SHADER_SOURCES}/*.frag")
set(BATTLEBLOCK_NATIVE_SHADER_SPV_DIR "${CMAKE_CURRENT_BINARY_DIR}/native_shaders")
set(BATTLEBLOCK_NATIVE_SHADER_CPP "${CMAKE_CURRENT_BINARY_DIR}/native_shaders_embedded.cpp")
if(BATTLEBLOCK_NATIVE_SHADER_FILES)
add_custom_command(
    OUTPUT "${BATTLEBLOCK_NATIVE_SHADER_CPP}"
    COMMAND "${CMAKE_COMMAND}" -E rm -rf "${BATTLEBLOCK_NATIVE_SHADER_SPV_DIR}"
    COMMAND python3 "${BATTLEBLOCK_NATIVE_SHADER_SOURCES}/build_native_shaders.py"
            "${BATTLEBLOCK_NATIVE_SHADER_SPV_DIR}" 0000400000000001
    COMMAND python3 "${CMAKE_CURRENT_SOURCE_DIR}/cmake/embed_native_shaders.py"
            "${BATTLEBLOCK_NATIVE_SHADER_SPV_DIR}" "${BATTLEBLOCK_NATIVE_SHADER_CPP}"
    DEPENDS ${BATTLEBLOCK_NATIVE_SHADER_FILES}
            "${BATTLEBLOCK_NATIVE_SHADER_SOURCES}/build_native_shaders.py"
            "${CMAKE_CURRENT_SOURCE_DIR}/cmake/embed_native_shaders.py"
    COMMENT "Building the native replacement shaders"
    VERBATIM)
else()
# Sin shaders de reemplazo todavía: tabla vacía válida generada con el mismo
# script (define kEmbeddedPixelShaders/kEmbeddedPixelShaderCount que el
# renderer nativo espera; count 0 = nunca se usan).
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/native_shaders_empty")
add_custom_command(
    OUTPUT "${BATTLEBLOCK_NATIVE_SHADER_CPP}"
    COMMAND python3 "${CMAKE_CURRENT_SOURCE_DIR}/cmake/embed_native_shaders.py"
            "${CMAKE_CURRENT_BINARY_DIR}/native_shaders_empty" "${BATTLEBLOCK_NATIVE_SHADER_CPP}"
    DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/embed_native_shaders.py"
    COMMENT "No native replacement shaders yet (empty table)"
    VERBATIM)
endif()

add_library(battleblock_host OBJECT src/main.cpp "${BATTLEBLOCK_NATIVE_SHADER_CPP}" src/draw_telemetry.cpp
    src/frame_pacing.cpp src/ring_wait.cpp src/subtitles.cpp src/startup_check.cpp
    src/native/native_system.cpp src/native/native_renderer.cpp
    src/native/native_textures.cpp src/native/native_geometry_shaders.cpp
    "${REXSDK_DIR}/src/ui/rex_app.cpp"
    "${REXSDK_DIR}/src/ui/windowed_app_main_switch.cpp")
# The native renderer uses the SDK's shader translator and gamma shader, whose
# headers rexruntime does not export: it links graphics, glslang and xxHash
# privately.
target_include_directories(battleblock_host PRIVATE "${BATTLEBLOCK_GENERATED_DIR}"
    "${REXSDK_DIR}/thirdparty/imgui"
    "${REXSDK_DIR}/src/graphics"
    "${REXSDK_DIR}/thirdparty/glslang"
    "${REXSDK_DIR}/thirdparty/xxHash")
target_link_libraries(battleblock_host PRIVATE rex::runtime)
target_compile_definitions(battleblock_host PRIVATE REXGLUE_BUILD_CONFIG="$<CONFIG>" BATTLEBLOCK_NATIVE_RENDERER=1)

add_custom_target(battleblock_switch_compile DEPENDS battleblock_recomp battleblock_host
    rexruntime rexglue_switch_startup)
if(NOT REXGLUE_SWITCH_COMPILE_ONLY)
    add_executable(battleblock $<TARGET_OBJECTS:battleblock_host> $<TARGET_OBJECTS:battleblock_recomp>)
    rexglue_switch_configure_target(battleblock NO_ENTRY)
    rexglue_switch_add_nro(battleblock NAME "BattleBlock Theater" AUTHOR "dashx" VERSION "0.2.0"
        ICON "${CMAKE_CURRENT_SOURCE_DIR}/switch/icon.jpg")
endif()
