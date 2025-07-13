#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Cross-platform build script for cmake-initializer projects

.DESCRIPTION
    Unified PowerShell script that builds the project on Windows, Linux, and macOS.
    Supports MSVC, Clang, and GCC compilers with automatic detection.
    
    This script automatically detects the project structure and uses appropriate CMake presets
    based on your platform and compiler choice. It supports static runtime linking for 
    portable builds and provides comprehensive build options.

.PARAMETER Preset
    CMake preset to use for building. If not specified, automatically determined based on
    platform and configuration:
    - Windows: windows-msvc-debug/release, windows-clang-debug/release
    - Unix-like: unixlike-gcc-debug/release, unixlike-clang-debug/release

.PARAMETER Config
    Build configuration to use. Must be either 'Debug' or 'Release'.
    Default: Release
    
    Debug builds include debug symbols and disable optimizations.
    Release builds enable optimizations and may strip debug symbols.

.PARAMETER Compiler
    Specific compiler to use. Must be one of: 'msvc', 'clang', 'gcc'.
    If not specified, uses platform default (MSVC on Windows, GCC on Unix-like).
    
    This parameter changes the CMake preset to use the specified compiler.
    - msvc: Only available on Windows, uses Visual Studio compiler
    - clang: Uses Clang/Clang-cl compiler
    - gcc: Uses GNU Compiler Collection

.PARAMETER Static
    Enable static runtime linking for portable builds. When enabled, links against
    static versions of runtime libraries to reduce external dependencies.
    Default: false (uses dynamic linking)
    
    Automatically applies correct flags based on compiler:
    - MSVC: /MT (static CRT)
    - GCC/Clang: -static-libstdc++ -static-libgcc
    - Intel: -static-intel

.PARAMETER BuildDir
    Base directory for build outputs. The actual build directory will be
    {BuildDir}/build/{Preset} relative to the workspace root.
    Default: "out"
    
    Examples:
    - "out" creates builds in ./out/build/{preset}/
    - "build" creates builds in ./build/build/{preset}/
    - "../builds" creates builds in ../builds/build/{preset}/

.PARAMETER Jobs
    Number of parallel build jobs to use during compilation. Higher values can
    speed up builds on multi-core systems but may increase memory usage.
    Default: Number of CPU cores detected on the system

.PARAMETER Verbose
    Enable verbose build output. Shows detailed compilation commands and progress
    information. Useful for debugging build issues.
    Default: false

.EXAMPLE
    .\scripts\build.ps1
    
    Build with default settings (Release configuration, auto-detected compiler,
    dynamic linking). This is the most common usage for development builds.

.EXAMPLE
    .\scripts\build.ps1 -Config Debug -Static -Verbose
    
    Build Debug configuration with static runtime linking and verbose output.
    Useful for creating portable debug builds with detailed build information.

.EXAMPLE
    .\scripts\build.ps1 -Compiler clang -Verbose
    
    Build with Clang compiler and verbose output.
    Good for testing with different compilers or debugging build issues.

.EXAMPLE
    .\scripts\build.ps1 -Config Release -Static -Jobs 16
    
    Build optimized release version with static linking using 16 parallel jobs.
    Ideal for creating fast, portable release builds on high-core-count systems.

.NOTES
    Requires CMake 3.21+ and appropriate compilers to be installed and available in PATH.
    The script automatically detects project structure and adapts to cmake-initializer
    project layout with project subdirectory.

.LINK
    https://github.com/01Pollux/cmake-initializer
#>
param(
    [string]$Preset = "",
    [ValidateSet("Debug", "Release")]
    [string]$Config = "Release",
    [ValidateSet("msvc", "clang", "gcc", "")]
    [string]$Compiler = "",
    [string]$BuildDir = "out",
    [switch]$Static,
    [int]$Jobs = 0,
    [switch]$Verbose
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Get script directory and project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Detect if we have a project subdirectory structure
$ProjectDir = $ProjectRoot
if (Test-Path (Join-Path $ProjectRoot "project\CMakePresets.json")) {
    $ProjectDir = Join-Path $ProjectRoot "project"
    Write-Host "Using project subdirectory: $ProjectDir" -ForegroundColor DarkGray
} elseif (-not (Test-Path (Join-Path $ProjectRoot "CMakePresets.json"))) {
    throw "Could not find CMakePresets.json in $ProjectRoot or $ProjectRoot\project"
}

# Determine number of jobs if not specified
if ($Jobs -eq 0) {
    $Jobs = [Environment]::ProcessorCount
}

# Platform detection
$Platform = if ($PSVersionTable.PSVersion.Major -ge 6) {
    if ($IsWindows) { "Windows" }
    elseif ($IsLinux) { "Linux" }
    else { "macOS" }
} else {
    if ($env:OS -eq "Windows_NT") { "Windows" } else { "Unix" }
}

Write-Host "🔨 cmake-initializer Build Script" -ForegroundColor Cyan
Write-Host "Platform: $Platform" -ForegroundColor Green

# Determine preset if not specified
if (-not $Preset) {
    if ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows) {
        $Preset = "windows-msvc-debug"
        if ($Config -eq "Release") { $Preset = "windows-msvc-release" }
    } elseif ($PSVersionTable.PSVersion.Major -lt 6 -and $env:OS -eq "Windows_NT") {
        $Preset = "windows-msvc-debug"
        if ($Config -eq "Release") { $Preset = "windows-msvc-release" }
    } else {
        $Preset = "unixlike-gcc-debug"
        if ($Config -eq "Release") { $Preset = "unixlike-gcc-release" }
    }
}

# Derive build configuration from preset name
if ($Preset -match "debug") {
    $Config = "Debug"
} elseif ($Preset -match "release") {
    $Config = "Release"
} else {
    # Default fallback
    $Config = "Release"
}

Write-Host "Configuration: $Config" -ForegroundColor Green
Write-Host "Preset: $Preset" -ForegroundColor Green

# Build CMake configuration arguments
$ConfigArgs = @()

# Add static linking if requested
if ($Static) {
    $ConfigArgs += "-DENABLE_STATIC_RUNTIME=ON"
    Write-Host "Static linking: Enabled" -ForegroundColor Yellow
}

# Add compiler-specific settings
if ($Compiler) {
    switch ($Compiler.ToLower()) {
        "msvc" {
            if (-not ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows) -and -not ($PSVersionTable.PSVersion.Major -lt 6 -and $env:OS -eq "Windows_NT")) {
                throw "MSVC compiler is only available on Windows"
            }
            if ($Config -eq "Debug") {
                $Preset = "windows-msvc-debug"
            } else {
                $Preset = "windows-msvc-release"
            }
        }
        "clang" {
            if (($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows) -or ($PSVersionTable.PSVersion.Major -lt 6 -and $env:OS -eq "Windows_NT")) {
                if ($Config -eq "Debug") {
                    $Preset = "windows-clang-debug"
                } else {
                    $Preset = "windows-clang-release"
                }
            } else {
                if ($Config -eq "Debug") {
                    $Preset = "unixlike-clang-debug"
                } else {
                    $Preset = "unixlike-clang-release"
                }
            }
        }
        "gcc" {
            if ($Config -eq "Debug") {
                $Preset = "unixlike-gcc-debug"
            } else {
                $Preset = "unixlike-gcc-release"
            }
        }
    }
    Write-Host "Compiler: $Compiler" -ForegroundColor Green
}

# Change to project directory
Push-Location $ProjectDir

try {
    # Validate preset exists before configuring
    Write-Host "⚙️  Configuring project..." -ForegroundColor Blue
    
    # Check if preset is available
    $AvailablePresets = & cmake --list-presets 2>$null | Where-Object { $_ -match '^\s*"([^"]+)"' } | ForEach-Object { $Matches[1] }
    if ($AvailablePresets -and $Preset -notin $AvailablePresets) {
        Write-Host "❌ Preset '$Preset' is not available on this platform." -ForegroundColor Red
        Write-Host "Available presets:" -ForegroundColor Yellow
        foreach ($p in $AvailablePresets) {
            Write-Host "  - $p" -ForegroundColor Yellow
        }
        throw "Invalid preset: $Preset"
    }
    
    # Configure the project - use workspace root for build output
    $BuildOutputDir = Join-Path $ProjectRoot "$BuildDir/build/$Preset"
    $ConfigCmd = @("cmake", "-S", ".", "-B", $BuildOutputDir, "--preset", $Preset) + $ConfigArgs
    
    if ($Verbose) {
        Write-Host "Command: $($ConfigCmd -join ' ')" -ForegroundColor DarkGray
    }
    
    & $ConfigCmd[0] $ConfigCmd[1..($ConfigCmd.Length-1)]
    if ($LASTEXITCODE -ne 0) {
        throw "Configuration failed with exit code $LASTEXITCODE"
    }

    # Build the project
    Write-Host "🔧 Building project..." -ForegroundColor Blue
    $BuildCmd = @("cmake", "--build", $BuildOutputDir, "--config", $Config, "--parallel", $Jobs)
    
    if ($Verbose) {
        $BuildCmd += "--verbose"
        Write-Host "Command: $($BuildCmd -join ' ')" -ForegroundColor DarkGray
    }
    
    & $BuildCmd[0] $BuildCmd[1..($BuildCmd.Length-1)]
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed with exit code $LASTEXITCODE"
    }

    Write-Host "✅ Build completed successfully!" -ForegroundColor Green
    
    # Show build information
    $ActualBuildDir = Join-Path $ProjectRoot "$BuildDir/build/$Preset"
    if (Test-Path $ActualBuildDir) {
        $BuildSize = (Get-ChildItem -Recurse $ActualBuildDir | Measure-Object -Property Length -Sum).Sum
        $BuildSizeMB = [math]::Round($BuildSize / 1MB, 2)
        Write-Host "Build directory size: ${BuildSizeMB} MB" -ForegroundColor Cyan
    }

} catch {
    Write-Host "❌ Build failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
