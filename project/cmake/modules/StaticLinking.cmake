# ==============================================================================
# Static Linking Module
# ==============================================================================
# This module provides functions to enable static linking of runtime libraries
# with automatic compiler detection for better portability across different systems.
# 
# Supports MSVC, GCC, Clang, Intel, and Emscripten compilers with appropriate
# static linking flags for each platform.

include_guard(GLOBAL)
include(GetCurrentCompiler)

# Enable static runtime linking for a specific target with auto-detection
# Usage:
# target_enable_static_linking(MyTarget)
function(target_enable_static_linking target)
    cmake_parse_arguments(ARG "" "" "" ${ARGN})
    
    if(NOT TARGET ${target})
        message(FATAL_ERROR "Target ${target} does not exist")
    endif()
    
    # Get current compiler
    get_current_compiler(CURRENT_COMPILER)
    
    # Apply compiler-specific static linking
    if(CURRENT_COMPILER STREQUAL "GCC" OR CURRENT_COMPILER STREQUAL "CLANG")
        target_link_options(${target} PRIVATE "-static-libstdc++" "-static-libgcc")
        message(STATUS "Enabling static runtime linking for ${CURRENT_COMPILER} target: ${target}")
    elseif(CURRENT_COMPILER STREQUAL "MSVC")
        set_target_properties(${target} PROPERTIES
            MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
        )
        message(STATUS "Enabling static runtime linking for MSVC target: ${target}")
    elseif(CURRENT_COMPILER STREQUAL "INTEL")
        target_link_options(${target} PRIVATE "-static-intel")
        message(STATUS "Enabling static runtime linking for Intel target: ${target}")
    elseif(CURRENT_COMPILER STREQUAL "EMSCRIPTEN")
        # Emscripten static linking: link C++ standard library statically
        target_link_options(${target} PRIVATE "-static-libstdc++")
        # For more portable/standalone WebAssembly output
        target_link_options(${target} PRIVATE "SHELL:-s STANDALONE_WASM=1")
        target_link_options(${target} PRIVATE "SHELL:-s WASM=1")
        message(STATUS "Enabling static runtime linking for Emscripten target: ${target}")
    else()
        message(WARNING "Static runtime linking not supported for compiler: ${CURRENT_COMPILER}")
    endif()
endfunction()

# Enable static linking for multiple targets
# Usage:
# targets_enable_static_linking(TARGETS MyTarget1 MyTarget2 MyTarget3)
function(targets_enable_static_linking)
    cmake_parse_arguments(ARG "" "" "TARGETS" ${ARGN})
    
    if(NOT ARG_TARGETS)
        message(FATAL_ERROR "targets_enable_static_linking() called without TARGETS")
    endif()
    
    foreach(target ${ARG_TARGETS})
        target_enable_static_linking(${target})
    endforeach()
endfunction()
