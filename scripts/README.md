# Build Scripts

This directory contains cross-platform PowerShell scripts for building, cleaning, and installing cmake-initializer projects.

## Getting Help

All scripts include comprehensive built-in help documentation accessible through PowerShell's help system:

```powershell
# Show basic help and syntax
Get-Help .\scripts\build.ps1

# Show detailed help with parameter descriptions and examples
Get-Help .\scripts\build.ps1 -Detailed

# Show just the examples
Get-Help .\scripts\build.ps1 -Examples

# Show complete help with technical details
Get-Help .\scripts\build.ps1 -Full
```

This works for all three scripts: `build.ps1`, `clean.ps1`, and `install.ps1`.

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
- `Clean` - Clean build directory before building
- `Install` - Install the project after building
- `Jobs` - Number of parallel build jobs (default: CPU cores)
- `Verbose` - Enable verbose build output

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

**Quick development build:**
```powershell
.\scripts\build.ps1 -Config Debug -Clean
```

**Release build for distribution:**
```powershell
.\scripts\build.ps1 -Config Release -Static -Install
```

**Full clean and rebuild:**
```powershell
.\scripts\clean.ps1 -All -Force
.\scripts\build.ps1 -Config Release -Static
```

**Test different compilers:**
```powershell
.\scripts\build.ps1 -Compiler gcc -Config Debug
.\scripts\build.ps1 -Compiler clang -Config Debug
.\scripts\build.ps1 -Compiler msvc -Config Debug
```
