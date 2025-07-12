# Build & Test Scripts

This directory contains cross-platform PowerShell scripts for building, testing, cleaning, and installing cmake-initializer projects.

## Getting Help

All scripts include comprehensive built-in help documentation accessible through PowerShell's help system:

```powershell
# Show basic help and syntax
Get-Help .\scripts\build.ps1
Get-Help .\scripts\test.ps1

# Show detailed help with parameter descriptions and examples
Get-Help .\scripts\build.ps1 -Detailed

# Show just the examples
Get-Help .\scripts\test.ps1 -Examples

# Show complete help with technical details
Get-Help .\scripts\clean.ps1 -Full
```

This works for all scripts: `build.ps1`, `test.ps1`, `clean.ps1`, and `install.ps1`.

## Scripts Overview

### `build.ps1` - Build Script
Cross-platform build script that works on Windows, Linux, and macOS.

**Basic Usage:**
```powershell
# Build with default settings (Release, auto-detected compiler)
.\scripts\build.ps1

# Build Debug configuration with static linking
.\scripts\build.ps1 -Config Debug -Static

# Build with specific compiler
.\scripts\build.ps1 -Compiler clang -Clean -Install

# Build with verbose output and multiple jobs
.\scripts\build.ps1 -Verbose -Jobs 8
```

**Parameters:**
- `Preset` - CMake preset to use (auto-detected by default)
- `Config` - Build configuration: Debug or Release (default: Release)
- `Compiler` - Specific compiler: msvc, clang, gcc (auto-detected by default)
- `Static` - Enable static runtime linking for portable builds
- `Jobs` - Number of parallel build jobs (default: CPU cores)
- `Verbose` - Enable verbose build output

### `test.ps1` - Test Script
Cross-platform test execution script with comprehensive testing features.

**Basic Usage:**
```powershell
# Run all tests with default settings
.\scripts\test.ps1

# Run tests in Debug configuration with verbose output
.\scripts\test.ps1 -Config Debug -Verbose

# Run specific tests with coverage
.\scripts\test.ps1 -Filter "Unit.*" -Coverage

# Run tests with JUnit output for CI/CD
.\scripts\test.ps1 -Output junit -Parallel 4
```

**Parameters:**
- `Config` - Build configuration: Debug or Release (default: Release)
- `Preset` - CMake test preset to use (auto-detected by default)
- `Compiler` - Specific compiler: msvc, clang, gcc (auto-detected by default)
- `Filter` - Regular expression pattern to filter tests
- `Parallel` - Number of parallel test jobs (default: CPU cores)
- `Output` - Output format: default, verbose, junit, json
- `Coverage` - Enable code coverage reporting
- `Repeat` - Number of times to repeat the test suite
- `Timeout` - Maximum time per test in seconds (default: 300)
- `Valgrind` - Run tests under Valgrind (Linux/macOS only)
- `Verbose` - Enable verbose test output

### `clean.ps1` - Clean Script
Removes build artifacts and generated files.

**Basic Usage:**
```powershell
# Clean build directory
.\scripts\clean.ps1

# Clean all artifacts including install directory
.\scripts\clean.ps1 -All -Force

# Only clean CMake cache files
.\scripts\clean.ps1 -Cache
```

**Parameters:**
- `All` - Remove all build artifacts including install directory
- `BuildDir` - Specific build directory to clean (default: "out")
- `Cache` - Only clean CMake cache files
- `Force` - Force removal without confirmation prompts
- `Verbose` - Enable verbose output showing what's being removed

### `install.ps1` - Install Script
Installs built artifacts to a specified location.

**Basic Usage:**
```powershell
# Install with default settings
.\scripts\install.ps1

# Install to specific location
.\scripts\install.ps1 -Prefix "C:\Program Files\MyProject"

# Dry run to see what would be installed
.\scripts\install.ps1 -DryRun
```

**Parameters:**
- `Config` - Build configuration to install: Debug or Release (default: Release)
- `Prefix` - Installation prefix directory (default: ./install)
- `Component` - Specific component to install (default: all)
- `BuildDir` - Build directory containing artifacts (default: "out")
- `Verbose` - Enable verbose installation output
- `DryRun` - Show what would be installed without actually installing
- `Force` - Force installation even if target already exists

## Static Linking for Portable Builds

Use the `-Static` flag with the build script to create portable executables:

```powershell
# Create portable build with static runtime linking
.\scripts\build.ps1 -Static -Config Release
```

This automatically applies the correct static linking flags for your compiler:
- **MSVC**: `/MT` (static CRT)
- **GCC/Clang**: `-static-libstdc++ -static-libgcc`
- **Intel**: `-static-intel`
- **Emscripten**: `-static-libstdc++` with standalone WASM output

## Cross-Platform Usage

These scripts work on all platforms with PowerShell Core 6+:

**Windows (PowerShell/Command Prompt):**
```cmd
.\scripts\build.ps1 -Config Debug -Static
```

**Linux/macOS (PowerShell Core):**
```bash
pwsh ./scripts/build.ps1 -Config Debug -Static
```

## Examples

**Quick development workflow:**
```powershell
# Build and test in Debug mode
.\scripts\build.ps1 -Config Debug
.\scripts\test.ps1 -Config Debug -Verbose
```

**Complete development cycle:**
```powershell
# Clean, build, and test
.\scripts\clean.ps1 -All -Force
.\scripts\build.ps1 -Config Release -Static
.\scripts\test.ps1 -Config Release -Coverage
```

**CI/CD pipeline simulation:**
```powershell
# Test with JUnit output and coverage
.\scripts\test.ps1 -Output junit -Coverage -Parallel 4
```

**Cross-compiler testing:**
```powershell
# Test with different compilers
.\scripts\build.ps1 -Compiler gcc -Config Debug
.\scripts\test.ps1 -Compiler gcc -Config Debug

.\scripts\build.ps1 -Compiler clang -Config Debug  
.\scripts\test.ps1 -Compiler clang -Config Debug
```

**Release build for distribution:**
```powershell
.\scripts\build.ps1 -Config Release -Static
.\scripts\test.ps1 -Config Release
.\scripts\install.ps1 -Config Release
```
