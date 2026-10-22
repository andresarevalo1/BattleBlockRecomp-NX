# battleblock - ReXGlue Recompiled Project (Switch)
#
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 DashX - Andres Arevalo
# Ver NOTICE en la raiz del repositorio para la atribucion del codigo de
# terceros del que deriva este proyecto.
# SDK boilerplate lives in generated/rexglue.cmake.

cmake_minimum_required(VERSION 3.25)
project(battleblock LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(REXGLUE_PLATFORM_SWITCH)
    include(cmake/switch.cmake)
    return()
endif()

include(generated/rexglue.cmake)

# Pass-through instrumentation of the guest draw-submission functions (see
# src/draw_telemetry.cpp) is always compiled in and gated at RUNTIME by the
# `draw_telemetry` cvar, which defaults off.
set(BATTLEBLOCK_SOURCES
    src/main.cpp
    src/draw_telemetry.cpp
    src/frame_pacing.cpp
    src/ring_wait.cpp
    src/subtitles.cpp
    src/startup_check.cpp
)

if(WIN32)
    add_executable(battleblock WIN32 ${BATTLEBLOCK_SOURCES})
else()
    add_executable(battleblock ${BATTLEBLOCK_SOURCES})
endif()

rexglue_setup_target(battleblock)

# The Switch port's native renderer (src/native, always built for Switch in
# cmake/switch.cmake). On a PC it is only for developing that renderer against
# a desktop GPU: with this on, --nx_renderer=native selects it; the default
# stays the emulated GPU.
option(BATTLEBLOCK_NATIVE_RENDERER "Build the Switch native renderer into the PC build (development)" OFF)
if(BATTLEBLOCK_NATIVE_RENDERER)
    target_sources(battleblock PRIVATE
        src/native/native_system.cpp src/native/native_renderer.cpp
        src/native/native_textures.cpp src/native/native_geometry_shaders.cpp)
    target_compile_definitions(battleblock PRIVATE BATTLEBLOCK_NATIVE_RENDERER=1)
    target_include_directories(battleblock PRIVATE
        "${REXSDK_DIR}/src/graphics"
        "${REXSDK_DIR}/thirdparty/glslang"
        "${REXSDK_DIR}/thirdparty/xxHash"
        "${REXSDK_DIR}/thirdparty/renderdoc")
    # rexruntime links xxHash privately; the renderer hashes with it directly.
    target_link_libraries(battleblock PRIVATE xxHash::xxhash)
endif()

# draw_telemetry.cpp calls fmt directly; the prebuilt SDK exposes fmt headers
# transitively, but REXSDK_DIR (add_subdirectory) builds -- what CI uses --
# need the explicit link for the target to see fmt's usage requirements.
if(TARGET fmt::fmt)
    target_link_libraries(battleblock PRIVATE fmt::fmt)
endif()

# Generated TUs: -O3 + x86-64-v3 como en releases de referencia.
set(BATTLEBLOCK_X86_MARCH "x86-64-v3" CACHE STRING
    "x86-64 microarchitecture level to compile the game for (x86-64-v3 or x86-64-v2)")
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU"
   AND CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
    target_compile_options(battleblock PRIVATE
        $<$<CONFIG:RelWithDebInfo,Release>:-O3>
        -march=${BATTLEBLOCK_X86_MARCH}
    )
endif()

# Windows POSIX shims for the few generated TUs that reference <sys/mman.h>
# (mprotect, neutered/no-op) and <unistd.h> (usleep). Scoped to this target.
if(WIN32)
    target_include_directories(battleblock PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/compat_win)
endif()
