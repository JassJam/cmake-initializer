# CMake Variables Reference

This document lists all available CMake cache variables that can be used in presets or command line configuration.

## Development Mode Presets

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `DEV_MODE` | BOOL | ON | Enable all development tools (warnings, sanitizers, static analysis) |
| `RELEASE_MODE` | BOOL | OFF | Enable release optimizations (IPO, stripped symbols, etc.) |

## Static Linking (Portability)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ENABLE_STATIC_RUNTIME` | BOOL | OFF | **Auto-detect compiler and link runtime statically** (recommended for portable builds) |

> **Tip**: Use `ENABLE_STATIC_RUNTIME=ON` for portable builds:
> - **MSVC**: `/MT` (static CRT)
> - **GCC/Clang**: `-static-libstdc++ -static-libgcc` 
> - **Emscripten**: `-static-libstdc++` with standalone WASM output

## Quality Options

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ENABLE_WARNINGS_AS_ERRORS` | BOOL | DEV_MODE | Treat compiler warnings as errors |
| `ENABLE_SANITIZERS` | BOOL | DEV_MODE | Enable address/undefined behavior sanitizers |
| `ENABLE_ASAN` | BOOL | SUPPORTS_ASAN | Address Sanitizer |
| `ENABLE_LSAN` | BOOL | OFF | Leak Sanitizer |
| `ENABLE_UBSAN` | BOOL | SUPPORTS_UBSAN | Undefined Behavior Sanitizer |
| `ENABLE_TSAN` | BOOL | OFF | Thread Sanitizer |
| `ENABLE_MSAN` | BOOL | OFF | Memory Sanitizer |
| `ENABLE_HARDENING` | BOOL | ENABLE_SANITIZERS OR DEV_MODE | Enable security hardening options (stack protection, etc.) |
| `ENABLE_STATIC_ANALYSIS` | BOOL | DEV_MODE | Enable clang-tidy and cppcheck |
| `ENABLE_CLANG_TIDY` | BOOL | ENABLE_STATIC_ANALYSIS | Enable clang-tidy static analysis |
| `ENABLE_CPPCHECK` | BOOL | ENABLE_STATIC_ANALYSIS | Enable cppcheck static analysis |

## Performance Options

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ENABLE_IPO` | BOOL | RELEASE_MODE | Enable link-time optimization (LTO) |
| `ENABLE_UNITY_BUILD` | BOOL | OFF | Enable unity builds for faster compilation |
| `ENABLE_PCH` | BOOL | OFF | Enable precompiled headers |

## Debug Options

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ENABLE_EDIT_AND_CONTINUE` | BOOL | DEV_MODE | Enable Edit and Continue support (MSVC `/ZI` flag, incremental linking). **Disables Control Flow Guard** |
| `ENABLE_DEBUG_INFO` | BOOL | DEV_MODE | Enable debug information generation (`/Zi` for MSVC, `-g` for GCC/Clang) |
| `DEBUG_INFO_LEVEL` | STRING | [0/2] (if DEV_MODE is on) | Debug info level for GCC/Clang: `0` (none), `1` (minimal), `2` (default), `3` (maximum) |

> **Note**: Edit and Continue is only supported on MSVC. For GCC/Clang, this option only affects debug information generation.
> Edit and Continue requires incremental linking, which may conflict with some optimizations and sanitizers.
> 
> **Security Note**: When Edit and Continue is enabled, Control Flow Guard (`/guard:cf`) is automatically disabled due to MSVC compiler incompatibility.

## Package Management

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `PACKAGE_MANAGER` | STRING | CPM;XMake | Package managers to enable (semicolon-separated): `CPM`, `XMake`, `CPM;XMake`, or empty |

> **Note**: For Emscripten builds, XMake is automatically disabled as it conflicts with the cross-compilation toolchain.
> Use `CPM` only for WebAssembly targets, or explicitly set `PACKAGE_MANAGER=CPM` in your preset.

## Testing Framework

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `DEFAULT_TEST_FRAMEWORK` | STRING | doctest | Auto-register test framework: `doctest`, `catch2`, `gtest`, `boost` |
| `BUILD_TESTING` | BOOL | ON | Enable/disable testing (CTest) |

## Emscripten-Specific Variables

When building with Emscripten, these additional variables are available:

| Variable | Type | Default | Description                                                       |
|----------|------|---------|-------------------------------------------------------------------|
| `ENABLE_EMSDK_AUTO_INSTALL` | BOOL | ON | **Automatically install EMSDK locally if not found (to .emsdk/)** |
| `CMAKE_CROSSCOMPILING_EMULATOR` | STRING | node | JavaScript engine for running tests                               |
| `CMAKE_EXECUTABLE_SUFFIX` | STRING | .js | File extension for executables                                    |
| `EMSCRIPTEN_ROOT` | STRING | auto-detected | Emscripten installation directory                                 |
| `EMSCRIPTEN_NODE_EXECUTABLE` | STRING | auto-detected | Path to Node.js executable for test execution                     |
| `EMSCRIPTEN_TEST_OPTIONS` | STRING | "" | Additional Node.js options for running tests                      |
