# Preset-Based Configuration Features

This document describes the advanced preset-based configuration features that automate test framework registration and CTest dashboard uploads.

## Auto Test Framework Registration

### Overview
Define `DEFAULT_TEST_FRAMEWORK` in your CMake preset to automatically register a testing framework without manual `register_test_framework()` calls.

### Supported Frameworks
- `doctest`
- `catch2`
- `gtest`
- `boost`

### Example Configuration

```json
{
    ...
    "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "DEFAULT_TEST_FRAMEWORK": "gtest"
    }
}
```

## Available Presets

| Platform | Development | Testing | Production |
|----------|-------------|---------|------------|
| **Windows** | `windows-[clang\|msvc]-debug` | `test-windows-[clang\|msvc]-[debug\|release]` | `windows-[clang\|msvc]-release` |
| **Linux** | `unixlike-[gcc\|clang]-debug` | `unixlike-[gcc\|clang]-[debug\|release]` | `unixlike-[gcc\|clang]-release` |
| **macOS** | `unixlike-[gcc\|clang]-debug` | `unixlike-[gcc\|clang]-[debug\|release]` | `unixlike-[gcc\|clang]-release` |

### Usage
```bash
# Configure with a 'unixlike-clang-debug' preset
cmake -S ./project -B build --preset unixlike-clang-debug

# Configure with a 'test-windows-msvc-debug' preset
cmake -S ./project -B build --preset test-windows-msvc-debug
```
