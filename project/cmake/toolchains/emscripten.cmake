# Emscripten toolchain file for WebAssembly builds
# This toolchain is used automatically by the RegisterEmscripten module

set(CMAKE_SYSTEM_NAME Emscripten)
set(CMAKE_SYSTEM_VERSION 1)

# Set the target architecture
set(CMAKE_SYSTEM_PROCESSOR x86)

# First, try to set up EMSDK if it's not available
if(NOT DEFINED ENV{EMSDK} OR NOT EXISTS "$ENV{EMSDK}")
    # Include the EMSDK manager to install it automatically
    include("${CMAKE_CURRENT_LIST_DIR}/../modules/EmsdkManager.cmake")
    ensure_emsdk_available()
endif()

# Find Emscripten SDK
if(DEFINED ENV{EMSDK})
    # Use EMSDK environment variable if set
    set(EMSCRIPTEN_ROOT_PATH "$ENV{EMSDK}/upstream/emscripten")
elseif(EXISTS "${CMAKE_CURRENT_LIST_DIR}/../../../build/_deps/emsdk-src")
    # Use automatically downloaded EMSDK
    set(EMSCRIPTEN_ROOT_PATH "${CMAKE_CURRENT_LIST_DIR}/../../../build/_deps/emsdk-src/upstream/emscripten")
else()
    # Try to find emcc in PATH
    find_program(EMCC_EXECUTABLE emcc)
    if(EMCC_EXECUTABLE)
        get_filename_component(EMSCRIPTEN_ROOT_PATH "${EMCC_EXECUTABLE}" DIRECTORY)
    endif()
endif()

# Set Emscripten compilers
if(EMSCRIPTEN_ROOT_PATH AND EXISTS "${EMSCRIPTEN_ROOT_PATH}")
    if(WIN32)
        set(CMAKE_C_COMPILER "${EMSCRIPTEN_ROOT_PATH}/emcc.bat")
        set(CMAKE_CXX_COMPILER "${EMSCRIPTEN_ROOT_PATH}/em++.bat")
        set(CMAKE_AR "${EMSCRIPTEN_ROOT_PATH}/emar.bat" CACHE FILEPATH "Emscripten ar")
        set(CMAKE_RANLIB "${EMSCRIPTEN_ROOT_PATH}/emranlib.bat" CACHE FILEPATH "Emscripten ranlib")
    else()
        set(CMAKE_C_COMPILER "${EMSCRIPTEN_ROOT_PATH}/emcc")
        set(CMAKE_CXX_COMPILER "${EMSCRIPTEN_ROOT_PATH}/em++")
        set(CMAKE_AR "${EMSCRIPTEN_ROOT_PATH}/emar" CACHE FILEPATH "Emscripten ar")
        set(CMAKE_RANLIB "${EMSCRIPTEN_ROOT_PATH}/emranlib" CACHE FILEPATH "Emscripten ranlib")
    endif()
    
    message(STATUS "Using Emscripten from: ${EMSCRIPTEN_ROOT_PATH}")
else()
    message(WARNING "Emscripten SDK not found. Please set EMSDK environment variable or ensure emcc is in PATH.")
endif()

# Don't run the linker on compiler check
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE)

# Set compiler IDs to help CMake recognize them as Emscripten
set(CMAKE_C_COMPILER_ID "Emscripten")
set(CMAKE_CXX_COMPILER_ID "Emscripten")

# Set the build type to Release if not specified
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Set default compilation flags
set(CMAKE_C_FLAGS_INIT "-s WASM=1")
set(CMAKE_CXX_FLAGS_INIT "-s WASM=1")

# Set executable suffix
set(CMAKE_EXECUTABLE_SUFFIX_C ".html")
set(CMAKE_EXECUTABLE_SUFFIX_CXX ".html")

# Set find root path mode
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Disable warnings about unused variables
set(CMAKE_POLICY_WARNING_CMP0054 NEW)
