# Emscripten toolchain file for WebAssembly builds
# This toolchain includes the official Emscripten toolchain and adds project-specific settings

# First, try to set up EMSDK if it's not available
if(NOT DEFINED ENV{EMSDK} OR NOT EXISTS "$ENV{EMSDK}")
    # Include the EMSDK manager to install it automatically
    include("${CMAKE_CURRENT_LIST_DIR}/../modules/EmsdkManager.cmake")
    ensure_emsdk_available()
endif()

# Find and include the official Emscripten toolchain
if(DEFINED ENV{EMSDK} AND EXISTS "$ENV{EMSDK}/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake")
    # Set up basic Emscripten configuration
    set(CMAKE_SYSTEM_NAME Emscripten)
    set(CMAKE_SYSTEM_VERSION 1)
    
    # Set compilers
    set(EMSCRIPTEN_ROOT_PATH "$ENV{EMSDK}/upstream/emscripten")
    if(WIN32)
        set(CMAKE_C_COMPILER "${EMSCRIPTEN_ROOT_PATH}/emcc.bat")
        set(CMAKE_CXX_COMPILER "${EMSCRIPTEN_ROOT_PATH}/em++.bat")
    else()
        set(CMAKE_C_COMPILER "${EMSCRIPTEN_ROOT_PATH}/emcc")
        set(CMAKE_CXX_COMPILER "${EMSCRIPTEN_ROOT_PATH}/em++")
    endif()
    
    message(STATUS "Using Emscripten from: ${EMSCRIPTEN_ROOT_PATH}")
else()
    message(FATAL_ERROR "Emscripten SDK not found. Please install EMSDK and set the EMSDK environment variable.")
endif()

# Set default compilation flags for WebAssembly
set(CMAKE_C_FLAGS_INIT "-s WASM=1")
set(CMAKE_CXX_FLAGS_INIT "-s WASM=1")

# Set executable suffix
set(CMAKE_EXECUTABLE_SUFFIX ".html")
