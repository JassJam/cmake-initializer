include(CheckSanitizerSupport)
include(CMakeDependentOption)

#

# Check what sanitizers are supported
check_sanitizers_support(SUPPORTS_UBSAN SUPPORTS_ASAN)

#

set(BUILD_TESTING ON CACHE BOOL "Build and enable testing")

set(ENABLE_CCACHE ON CACHE BOOL "Enable ccache for faster rebuilds")
mark_as_advanced(ENABLE_CCACHE)

set(CPM_DOWNLOAD_VERSION "0.40.8" CACHE STRING "CPM version to download")
set(CPM_HASH_SUM "78ba32abdf798bc616bab7c73aac32a17bbd7b06ad9e26a6add69de8f3ae4791" CACHE STRING "CPM download hash")
set(CPM_REPOSITORY_URL "https://github.com/cpm-cmake/CPM.cmake" CACHE STRING "CPM repository URL")

# === MAIN CONFIGURATION OPTIONS ===
option(DEV_MODE "Enable development mode (all quality tools)" ON)
option(RELEASE_MODE "Enable release optimizations" OFF)

# === QUALITY TOOLS ===
option(ENABLE_SANITIZERS "Enable address/undefined behavior sanitizers" ${DEV_MODE})
option(ENABLE_STATIC_ANALYSIS "Enable clang-tidy and cppcheck" ${DEV_MODE})
option(ENABLE_WARNINGS_AS_ERRORS "Treat warnings as errors" ${DEV_MODE})

# === PERFORMANCE OPTIONS ===
option(ENABLE_IPO "Enable link-time optimization (LTO)" ${RELEASE_MODE})
option(ENABLE_UNITY_BUILD "Enable unity builds for faster compilation" OFF)
option(ENABLE_PCH "Enable precompiled headers" OFF)

# === SANITIZER OPTIONS ===
if(DEV_MODE OR ENABLE_SANITIZERS)
    set(DEFAULT_ASAN ${SUPPORTS_ASAN})
    set(DEFAULT_UBSAN ${SUPPORTS_UBSAN})
else()
    set(DEFAULT_ASAN OFF)
    set(DEFAULT_UBSAN OFF)
endif()

option(ENABLE_ASAN "Enable address sanitizer (detects memory errors)" ${DEFAULT_ASAN})
option(ENABLE_LSAN "Enable leak sanitizer (detects memory leaks)" OFF)
option(ENABLE_UBSAN "Enable undefined behavior sanitizer" ${DEFAULT_UBSAN})
option(ENABLE_TSAN "Enable thread sanitizer (detects data races)" OFF)
option(ENABLE_MSAN "Enable memory sanitizer (detects uninitialized reads)" OFF)

# === STATIC ANALYSIS OPTIONS ===
option(ENABLE_CLANG_TIDY "Enable clang-tidy static analysis" ${ENABLE_STATIC_ANALYSIS})
option(ENABLE_CPPCHECK "Enable cppcheck static analysis" ${ENABLE_STATIC_ANALYSIS})

# === LINKING OPTIONS ===
option(ENABLE_STATIC_RUNTIME "Statically link runtime libraries for better portability" OFF)

# === EMSCRIPTEN OPTIONS ===
option(ENABLE_EMSDK_AUTO_INSTALL "Automatically install EMSDK locally if not found" ON)

# Mark advanced options
mark_as_advanced(
    ENABLE_ASAN ENABLE_LSAN ENABLE_UBSAN ENABLE_TSAN ENABLE_MSAN
    ENABLE_CLANG_TIDY ENABLE_CPPCHECK
    ENABLE_UNITY_BUILD ENABLE_PCH
    ENABLE_EMSDK_AUTO_INSTALL
)

# Set up global hardening based on sanitizer settings
cmake_dependent_option(
    ENABLE_HARDENING
    "Enable security hardening options (stack protection, etc.)"
    ON "ENABLE_SANITIZERS OR DEV_MODE" OFF
)

# Print configuration summary
message(STATUS "=== ${THIS_PROJECT_PRETTY_NAME} Configuration ===")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "DEV_MODE: ${DEV_MODE}")
message(STATUS "RELEASE_MODE: ${RELEASE_MODE}")
message(STATUS "Sanitizers: ${ENABLE_SANITIZERS} (ASan:${ENABLE_ASAN}, UBSan:${ENABLE_UBSAN})")
message(STATUS "Static analysis: ${ENABLE_STATIC_ANALYSIS} (clang-tidy:${ENABLE_CLANG_TIDY}, cppcheck:${ENABLE_CPPCHECK})")
message(STATUS "Static linking: runtime:${ENABLE_STATIC_RUNTIME}")

# Configure static linking flags with auto-detection
if(ENABLE_STATIC_RUNTIME)
    include(GetCurrentCompiler)
    get_current_compiler(CURRENT_COMPILER)
    
    message(STATUS "Auto-enabling static linking of all runtime libraries for ${CURRENT_COMPILER}")
    
    set(STATIC_LINK_FLAGS "")
    
    # Apply compiler-specific static linking
    if(CURRENT_COMPILER STREQUAL "GCC" OR CURRENT_COMPILER STREQUAL "CLANG")
        list(APPEND STATIC_LINK_FLAGS "-static-libstdc++" "-static-libgcc")
        message(STATUS "Enabling static linking of libstdc++ and libgcc for ${CURRENT_COMPILER}")
    elseif(CURRENT_COMPILER STREQUAL "MSVC")
        # For MSVC, use /MT instead of /MD for static runtime
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>" CACHE STRING "MSVC runtime library" FORCE)
        message(STATUS "Enabling static runtime linking for MSVC")
    elseif(CURRENT_COMPILER STREQUAL "INTEL")
        list(APPEND STATIC_LINK_FLAGS "-static-intel")
        message(STATUS "Enabling static linking for Intel compiler")
    else()
        message(WARNING "Static linking configuration not defined for compiler: ${CURRENT_COMPILER}")
    endif()
    
    # Apply flags globally if any were set
    if(STATIC_LINK_FLAGS)
        string(REPLACE ";" " " STATIC_LINK_FLAGS_STR "${STATIC_LINK_FLAGS}")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${STATIC_LINK_FLAGS_STR}")
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${STATIC_LINK_FLAGS_STR}")
    endif()
endif()
