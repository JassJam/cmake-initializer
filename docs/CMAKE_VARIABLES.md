# CMake Variables Reference

This document lists all available CMake cache variables that can be used in presets or command line configuration.

## Basic Build Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `CMAKE_BUILD_TYPE` | STRING | Debug | Build type: `Debug`, `Release`, `RelWithDebInfo`, `MinSizeRel` |
| `CMAKE_EXPORT_COMPILE_COMMANDS` | BOOL | ON | Generate `compile_commands.json` for IDE support |
| `CMAKE_C_COMPILER` | STRING | - | C compiler executable (gcc, clang, cl.exe) |
| `CMAKE_CXX_COMPILER` | STRING | - | C++ compiler executable (g++, clang++, cl.exe) |

## Development Mode Presets

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `DEV_MODE` | BOOL | ON | Enable all development tools (warnings, sanitizers, static analysis) |
| `RELEASE_MODE` | BOOL | OFF | Enable release optimizations (IPO, stripped symbols, etc.) |

## Static Linking (Portability)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ENABLE_STATIC_RUNTIME` | BOOL | OFF | **Auto-detect compiler and link runtime statically** (recommended for portable builds) |

> **Tip**: Use `ENABLE_STATIC_RUNTIME=ON` for portable builds. It automatically applies the correct flags for your compiler:
> - **MSVC**: `/MT` (static CRT)
> - **GCC/Clang**: `-static-libstdc++ -static-libgcc` 
> - **Intel**: `-static-intel`
> - **Emscripten**: `-static-libstdc++` with standalone WASM output

## Quality Tools

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ENABLE_WARNINGS_AS_ERRORS` | BOOL | DEV_MODE | Treat compiler warnings as errors |
| `ENABLE_SANITIZERS` | BOOL | DEV_MODE | Enable address/undefined behavior sanitizers |
| `ENABLE_STATIC_ANALYSIS` | BOOL | DEV_MODE | Enable clang-tidy and cppcheck |

## Individual Sanitizers

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ENABLE_ASAN` | BOOL | SUPPORTS_ASAN | Address Sanitizer (detects memory errors) |
| `ENABLE_LSAN` | BOOL | OFF | Leak Sanitizer (detects memory leaks) |
| `ENABLE_UBSAN` | BOOL | SUPPORTS_UBSAN | Undefined Behavior Sanitizer |
| `ENABLE_TSAN` | BOOL | OFF | Thread Sanitizer (detects data races) |
| `ENABLE_MSAN` | BOOL | OFF | Memory Sanitizer (detects uninitialized reads) |

> **Note**: TSAN and ASAN cannot be used together.

## Static Analysis Tools

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ENABLE_CLANG_TIDY` | BOOL | ENABLE_STATIC_ANALYSIS | Enable clang-tidy static analysis |
| `ENABLE_CPPCHECK` | BOOL | ENABLE_STATIC_ANALYSIS | Enable cppcheck static analysis |

## Performance Options

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ENABLE_IPO` | BOOL | RELEASE_MODE | Enable link-time optimization (LTO) |
| `ENABLE_UNITY_BUILD` | BOOL | OFF | Enable unity builds for faster compilation |
| `ENABLE_PCH` | BOOL | OFF | Enable precompiled headers |

## Security Hardening

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ENABLE_HARDENING` | BOOL | ENABLE_SANITIZERS OR DEV_MODE | Enable security hardening options (stack protection, etc.) |

## Testing Framework

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `DEFAULT_TEST_FRAMEWORK` | STRING | doctest | Auto-register test framework: `doctest`, `catch2`, `gtest`, `boost` |
| `BUILD_TESTING` | BOOL | ON | Enable/disable testing (CTest) |

## Example Configurations

### Development Build
```json
{
  "cacheVariables": {
    "CMAKE_BUILD_TYPE": "Debug",
    "DEV_MODE": true,
    "ENABLE_ASAN": true,
    "ENABLE_UBSAN": true,
    "ENABLE_WARNINGS_AS_ERRORS": true
  }
}
```

### Portable Release Build
```json
{
  "cacheVariables": {
    "CMAKE_BUILD_TYPE": "Release",
    "ENABLE_STATIC_RUNTIME": true,
    "DEV_MODE": false,
    "RELEASE_MODE": true,
    "ENABLE_IPO": true
  }
}
```

### Fast Debug Build
```json
{
  "cacheVariables": {
    "CMAKE_BUILD_TYPE": "Debug",
    "ENABLE_UNITY_BUILD": true,
    "ENABLE_PCH": true,
    "DEV_MODE": false
  }
}
```

### Security-Hardened Build
```json
{
  "cacheVariables": {
    "CMAKE_BUILD_TYPE": "Release", 
    "ENABLE_HARDENING": true,
    "ENABLE_STATIC_RUNTIME": true,
    "ENABLE_WARNINGS_AS_ERRORS": true
  }
}
```

### WebAssembly/Emscripten Build
```json
{
  "cacheVariables": {
    "CMAKE_BUILD_TYPE": "Release",
    "CMAKE_C_COMPILER": "emcc",
    "CMAKE_CXX_COMPILER": "em++",
    "CMAKE_EXECUTABLE_SUFFIX": ".html",
    "ENABLE_STATIC_RUNTIME": true
  }
}
```

## Emscripten-Specific Variables

When building with Emscripten, these additional variables are available:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ENABLE_EMSDK_AUTO_INSTALL` | BOOL | ON | **Automatically install EMSDK locally if not found** |
| `CMAKE_CROSSCOMPILING_EMULATOR` | STRING | node | JavaScript engine for running tests |
| `CMAKE_EXECUTABLE_SUFFIX` | STRING | .js | File extension for executables |
| `EMSCRIPTEN_ROOT` | STRING | auto-detected | Emscripten installation directory |
| `EMSCRIPTEN_NODE_EXECUTABLE` | STRING | auto-detected | Path to Node.js executable for test execution |
| `EMSCRIPTEN_TEST_OPTIONS` | STRING | "" | Additional Node.js options for running tests |

### EMSDK Auto-Installation

The framework automatically handles EMSDK installation:

- **Enabled by default**: `ENABLE_EMSDK_AUTO_INSTALL=ON`
- **Local installation**: Downloads to `.emsdk/` directory (ignored by git)
- **Zero-setup builds**: Just run `.\scripts\build.ps1 -Compiler emscripten`
- **Setup script**: Generates `setup_emscripten.sh/.bat` for manual use

Disable auto-installation with:
```json
{
  "cacheVariables": {
    "ENABLE_EMSDK_AUTO_INSTALL": false
  }
}
```

### Emscripten Optimization Flags

The framework automatically applies these optimizations for Emscripten builds:

- **Debug**: `-s ASSERTIONS=1 -s SAFE_HEAP=1 -s DEMANGLE_SUPPORT=1`
- **Release**: `-O3 --closure 1 -s STANDALONE_WASM=1`
- **Static Runtime**: `-static-libstdc++ -s WASM=1`

## Command Line Usage

You can override any of these variables from the command line:

```bash
# Portable release build
cmake --preset unixlike-gcc-release -DENABLE_STATIC_RUNTIME=ON

# Development build with specific sanitizers
cmake --preset unixlike-gcc-debug -DENABLE_TSAN=ON -DENABLE_ASAN=OFF

# Fast compilation build
cmake --preset windows-msvc-debug -DENABLE_UNITY_BUILD=ON -DENABLE_PCH=ON
```
