# CMake Preset Configuration Guide

Advanced preset-based configuration for automated testing and streamlined development workflows.

## Auto Test Framework Registration

### Preset-Based Framework Selection

Define `DEFAULT_TEST_FRAMEWORK` in your CMake preset to automatically register a testing framework without manual `register_test_framework()` calls.

#### Supported Frameworks
| Framework | Preset Value |
|-----------|--------------|
| DocTest | `doctest` |
| Catch2 | `catch2` |
| Google Test | `gtest` |
| Boost.Test | `boost` |

#### Example Configuration
```json
{
    "name": "my-debug-preset",
    "displayName": "Debug Build with Testing",
    "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "DEFAULT_TEST_FRAMEWORK": "gtest",
        "BUILD_TESTING": "ON"
    }
}
```

## Available Presets

### Platform Matrix

| Platform | Development | Testing | Production |
|----------|-------------|---------|------------|
| **Windows** | `windows-[msvc\|clang]-debug` | `test-windows-[msvc\|clang]-[debug\|release]` | `windows-[msvc\|clang]-release` |
| **Linux** | `unixlike-[gcc\|clang]-debug` | `test-unixlike-[gcc\|clang]-[debug\|release]` | `unixlike-[gcc\|clang]-release` |
| **macOS** | `unixlike-[gcc\|clang]-debug` | `test-unixlike-[gcc\|clang]-[debug\|release]` | `unixlike-[gcc\|clang]-release` |

### Preset Categories

#### **Development Presets**
- **Purpose**: Daily development with debugging support
- **Features**: Debug symbols, minimal optimizations, development tools enabled
- **Pattern**: `{platform}-{compiler}-debug`

#### **Testing Presets**
- **Purpose**: Automated testing and validation
- **Features**: Testing frameworks enabled, optimized test execution
- **Pattern**: `test-{platform}-{compiler}-{config}`

#### **Production Presets**
- **Purpose**: Optimized builds for deployment
- **Features**: Maximum optimizations, minimal debug info, security hardening
- **Pattern**: `{platform}-{compiler}-release`

## Usage Examples

### Development Workflow

**Using Scripts (Recommended):**
```powershell
# Quick development build
.\scripts\build.ps1 --preset windows-msvc-debug
.\scripts\test.ps1 --preset test-windows-msvc-debug

# Cross-platform development
.\scripts\build.ps1 --preset unixlike-clang-debug
.\scripts\test.ps1 --preset test-unixlike-clang-debug
```

**Manual Commands (Alternative):**
```bash
# Quick development build
cmake -S ./project -B build --preset windows-msvc-debug
cmake --build build
```

### Automated Testing

**Using Scripts (Recommended):**
```powershell
# Comprehensive testing workflow
.\scripts\build.ps1 -Preset test-windows-msvc-release -Config Release
.\scripts\test.ps1 -Preset test-windows-msvc-release -Coverage -Output junit
```

**Manual Commands (Alternative):**
```bash
# Run comprehensive testing
cmake -S ./project -B build --preset test-windows-msvc-release
cmake --build build
ctest --test-dir build --output-on-failure
```

### Production Deployment

**Using Scripts (Recommended):**
```powershell
# Complete production workflow
.\scripts\clean.ps1 -All -Force
.\scripts\build.ps1 -Preset windows-msvc-release -Static
.\scripts\test.ps1 -Preset test-windows-msvc-release
.\scripts\install.ps1 -Config Release
```

**Manual Commands (Alternative):**
```bash
# Optimized release build
cmake -S ./project -B build --preset windows-msvc-release
cmake --build build --config Release
cmake --install build --config Release
```

## Custom Preset Creation

### Basic Template
```json
{
    "version": 3,
    "configurePresets": [
        {
            "name": "my-custom-preset",
            "displayName": "My Custom Configuration",
            "generator": "Ninja",
            "binaryDir": "out/build/${presetName}",
            "cacheVariables": {
                "CMAKE_BUILD_TYPE": "Release",
                "DEFAULT_TEST_FRAMEWORK": "doctest",
                "ENABLE_STATIC_RUNTIME": "ON"
            }
        }
    ]
}
```

### Advanced Preset Features
```json
{
    "name": "advanced-preset",
    "inherits": "base-preset",
    "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Windows"
    },
    "cacheVariables": {
        "CMAKE_BUILD_TYPE": "RelWithDebInfo",
        "ENABLE_SANITIZERS": "ON",
        "ENABLE_STATIC_ANALYSIS": "ON"
    },
    "environment": {
        "CC": "clang-cl",
        "CXX": "clang-cl"
    }
}
```
