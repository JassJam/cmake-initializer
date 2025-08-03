include(CheckSanitizerSupport)
include(CMakeDependentOption)

#

# Check what sanitizers are supported
check_sanitizers_support(SUPPORTS_UBSAN SUPPORTS_ASAN)

#

# === TEST CONFIGURATION OPTIONS ===
set(BUILD_TESTING ON CACHE BOOL "Build and enable testing")

# === CACHE CONFIGURATION OPTIONS ===
set(ENABLE_CCACHE ON CACHE BOOL "Enable ccache for faster rebuilds")

mark_as_advanced(ENABLE_CCACHE)

# === PACKAGE MANAGEMENT OPTIONS ===
set(CPM_DOWNLOAD_VERSION "0.40.8" CACHE STRING "CPM version to download")
set(CPM_HASH_SUM "78ba32abdf798bc616bab7c73aac32a17bbd7b06ad9e26a6add69de8f3ae4791" CACHE STRING "CPM download hash")
set(CPM_REPOSITORY_URL "https://github.com/cpm-cmake/CPM.cmake" CACHE STRING "CPM repository URL")

# === MAIN CONFIGURATION OPTIONS ===
option(DEV_MODE "Enable development mode (all quality tools)" ON)
option(RELEASE_MODE "Enable release optimizations" OFF)

# === GLOBAL OPTIONS ===
set(ENABLE_GLOBAL_EXCEPTIONS "ON" CACHE STRING "Enable global exception handling")
set(ENABLE_GLOBAL_WARNINGS_AS_ERRORS "${DEV_MODE}" CACHE STRING "Enable global warnings as errors")
set(ENABLE_GLOBAL_SANITIZERS "${DEV_MODE}" CACHE STRING "Enable global sanitizers")
set(ENABLE_GLOBAL_HARDENING "${DEV_MODE}" CACHE STRING "Enable global hardening")
set(ENABLE_GLOBAL_STATIC_ANALYSIS "${DEV_MODE}" CACHE STRING "Enable global static analysis")

# === PERFORMANCE OPTIONS ===
option(ENABLE_GLOBAL_IPO "Enable global link-time optimization (LTO)" ${RELEASE_MODE})

# === SANITIZER OPTIONS ===
if(DEV_MODE OR ENABLE_GLOBAL_SANITIZERS)
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
set(ENABLE_CLANG_TIDY "${ENABLE_GLOBAL_STATIC_ANALYSIS}" CACHE STRING "Enable clang-tidy static analysis" )
set(ENABLE_CPPCHECK "${ENABLE_GLOBAL_STATIC_ANALYSIS}" CACHE STRING "Enable cppcheck static analysis" ${ENABLE_GLOBAL_STATIC_ANALYSIS})

# === LINKING OPTIONS ===
option(ENABLE_STATIC_RUNTIME "Statically link runtime libraries for better portability" OFF)

# === EMSCRIPTEN OPTIONS ===
option(ENABLE_EMSDK_AUTO_INSTALL "Automatically install EMSDK locally if not found" ON)

#

# Mark advanced options
mark_as_advanced(
    ENABLE_ASAN ENABLE_LSAN ENABLE_UBSAN ENABLE_TSAN ENABLE_MSAN
    ENABLE_CLANG_TIDY ENABLE_CPPCHECK
    ENABLE_UNITY_BUILD ENABLE_PCH
    ENABLE_EMSDK_AUTO_INSTALL
    ENABLE_EXCEPTIONS
)

# Set up global hardening based on sanitizer settings
cmake_dependent_option(
    ENABLE_HARDENING
    "Enable security hardening options (stack protection, etc.)"
    ON "ENABLE_GLOBAL_SANITIZERS OR DEV_MODE" OFF
)

# Apply global hardening immediately if enabled
if(ENABLE_GLOBAL_HARDENING)
    include(TargetHardening)
    enable_global_hardening()
endif()

# Apply global IPO if enabled
if(ENABLE_GLOBAL_IPO)
    include(EnableInterproceduralOptimization)
    enable_global_interprocedural_optimization()
endif()

# Apply global sanitizers if enabled
if(ENABLE_GLOBAL_SANITIZERS)
    include(TargetSanitizers)
    enable_global_sanitizers()
endif()

# Apply global exceptions settings
if(ENABLE_GLOBAL_EXCEPTIONS)
    include(TargetExceptions)
    configure_global_exceptions(${ENABLE_GLOBAL_EXCEPTIONS})
endif()

# Apply global static analysis if enabled
if(ENABLE_GLOBAL_STATIC_ANALYSIS)
    include(StaticAnalysis)
    set(STATIC_ANALYSIS_ARGS)
    if(ENABLE_CLANG_TIDY_VALUE)
        list(APPEND STATIC_ANALYSIS_ARGS ENABLE_CLANG_TIDY)
    endif()
    if(ENABLE_CPPCHECK_VALUE)
        list(APPEND STATIC_ANALYSIS_ARGS ENABLE_CPPCHECK)
    endif()
    if(ENABLE_EXCEPTIONS)
        list(APPEND STATIC_ANALYSIS_ARGS ENABLE_EXCEPTIONS)
    endif()

    enable_global_static_analysis()
endif()

# Configure static linking flags with auto-detection
if(ENABLE_STATIC_RUNTIME)
    include(StaticLinking)
    enable_static_linking()
endif()

# Print configuration summary
message(STATUS "=== ${THIS_PROJECT_PRETTY_NAME} Configuration ===")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "DEV_MODE: ${DEV_MODE}")
message(STATUS "RELEASE_MODE: ${RELEASE_MODE}")
message(STATUS "Sanitizers: ${ENABLE_GLOBAL_SANITIZERS} (ASan:${ENABLE_ASAN}, UBSan:${ENABLE_UBSAN})")
message(STATUS "Static analysis: ${ENABLE_GLOBAL_STATIC_ANALYSIS} (clang-tidy:${ENABLE_CLANG_TIDY}, cppcheck:${ENABLE_CPPCHECK})")
message(STATUS "Debug options: Edit&Continue:${ENABLE_EDIT_AND_CONTINUE}, DebugInfo:${ENABLE_DEBUG_INFO} (level:${DEBUG_INFO_LEVEL})")
message(STATUS "Static linking: runtime:${ENABLE_STATIC_RUNTIME}")
message(STATUS "=== End of Configuration ===")