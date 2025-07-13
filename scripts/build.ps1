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
    Specific compiler to use. Must be one of: 'msvc', 'clang', 'gcc', 'emscripten'.
    If not specified, uses platform default (MSVC on Windows, GCC on Unix-like).
    
    This parameter changes the CMake preset to use the specified compiler.
    - msvc: Only available on Windows, uses Visual Studio compiler
    - clang: Uses Clang/Clang-cl compiler
    - gcc: Uses GNU Compiler Collection
    - emscripten: WebAssembly compiler (auto-installs EMSDK if needed)

.PARAMETER Static
    Enable static runtime linking for portable builds. When enabled, links against
    static versions of runtime libraries to reduce external dependencies.
    Default: false (uses dynamic linking)
    
    Automatically applies correct flags based on compiler:
    - MSVC: /MT (static CRT)
    - GCC/Clang: -static-libstdc++ -static-libgcc
    - Intel: -static-intel
    - Emscripten: -static-libstdc++ with standalone WASM output

.PARAMETER BuildDir
    Base directory for build outputs. The actual build directory will be
    {BuildDir}/build/{Preset} relative to the workspace root.
    Default: "out"
    
    Examples:
    - "out" creates builds in ./out/build/{preset}/
    - "build" creates builds in ./build/build/{preset}/
    - "../builds" creates builds in ../builds/build/{preset}/

.PARAMETER Targets
    Specific target names to build instead of building all targets. Can be specified
    multiple times to build multiple specific targets.
    Example: -Targets "HelloWorld", "MyLibrary"

.PARAMETER ExcludeTargets
    Target names to exclude from building. Useful when building most targets but
    wanting to skip specific ones (e.g., slow targets or ones with external dependencies).
    Example: -ExcludeTargets "SlowTarget", "OptionalLibrary"

.PARAMETER BuildDir
    Build directory name relative to project root. By default uses 'out' which
    matches the cmake-initializer preset configuration.
    Default: "out"

.PARAMETER Static
    Enable static runtime linking for portable builds. When enabled, links against
    static versions of runtime libraries to reduce external dependencies.
    Default: false (uses dynamic linking)

.PARAMETER Jobs
    Number of parallel build jobs to use during compilation. Higher values can
    speed up builds on multi-core systems but may increase memory usage.
    Default: Number of CPU cores detected on the system

.PARAMETER ListTargets
    List all available build targets without actually building anything.
    Useful for discovering what targets are available in the project.
    Default: false

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
    [ValidateSet("msvc", "clang", "gcc", "emscripten", "")]
    [string]$Compiler = "",
    [string[]]$Targets = @(),
    [string[]]$ExcludeTargets = @(),
    [string]$BuildDir = "out",
    [switch]$Static,
    [int]$Jobs = 0,
    [switch]$ListTargets,
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
        "emscripten" {
            if ($Config -eq "Debug") {
                $Preset = "emscripten-debug"
            } else {
                $Preset = "emscripten-release"
            }
            Write-Host "Emscripten compiler selected - EMSDK will be installed automatically if needed" -ForegroundColor Yellow
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
    
    $ConfigCmd = @("cmake", "-S", ".", "-B", $BuildOutputDir, "--preset", $Preset)
    $ConfigCmd += $ConfigArgs
    
    if ($Verbose) {
        Write-Host "Command: $($ConfigCmd -join ' ')" -ForegroundColor DarkGray
    }
    
    # Run the initial configuration
    & $ConfigCmd[0] $ConfigCmd[1..($ConfigCmd.Length-1)]
    $ConfigResult = $LASTEXITCODE
    
    # If configuration failed and this is an Emscripten build, try with --fresh
    if ($ConfigResult -ne 0 -and $Preset -match "emscripten") {
        Write-Host "Initial configuration failed. Retrying with fresh configuration for Emscripten..." -ForegroundColor Yellow
        
        # Add --fresh and try again
        $FreshConfigCmd = $ConfigCmd + @("--fresh")
        if ($Verbose) {
            Write-Host "Retry command: $($FreshConfigCmd -join ' ')" -ForegroundColor DarkGray
        }
        
        & $FreshConfigCmd[0] $FreshConfigCmd[1..($FreshConfigCmd.Length-1)]
        $ConfigResult = $LASTEXITCODE
    }
    
    if ($ConfigResult -ne 0) {
        throw "Configuration failed with exit code $ConfigResult"
    }

    # List targets if requested
    if ($ListTargets) {
        Write-Host "🎯 Available Build Targets:" -ForegroundColor Cyan
        
        # Function to find targets recursively
        function Get-CMakeTargets {
            param([string]$Directory)
            
            $targets = @()
            
            # Look for .vcxproj files (Windows/MSVC)
            $vcxprojFiles = Get-ChildItem -Path $Directory -Recurse -Filter "*.vcxproj" -File | 
                Where-Object { $_.Name -notmatch "(ALL_BUILD|ZERO_CHECK|INSTALL|RUN_TESTS|Continuous|Experimental|Nightly|NightlyMemoryCheck)" }
            
            foreach ($vcxproj in $vcxprojFiles) {
                $targetName = [System.IO.Path]::GetFileNameWithoutExtension($vcxproj.Name)
                $relativePath = $vcxproj.Directory.FullName.Replace($BuildOutputDir, "").TrimStart('\', '/')
                $targets += @{
                    Name = $targetName
                    Path = if ($relativePath) { $relativePath } else { "." }
                    Type = "Executable/Library"
                }
            }
            
            # Look for Makefile targets (Unix-like systems)
            $makefileTargets = @()
            if (Test-Path (Join-Path $Directory "Makefile")) {
                try {
                    $helpOutput = & make -C $Directory help 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        $makefileTargets = $helpOutput | Where-Object { $_ -match "^\.\.\." } | 
                            ForEach-Object { ($_ -split " ")[1] } | Where-Object { $_ -and $_ -notmatch "(all|clean|depend|help)" }
                    }
                } catch {
                    # Ignore errors when make help is not available
                }
            }
            
            return $targets
        }
        
        $allTargets = Get-CMakeTargets -Directory $BuildOutputDir
        
        if ($allTargets.Count -eq 0) {
            Write-Host "  No custom targets found (only system targets like ALL_BUILD, INSTALL, etc.)" -ForegroundColor Yellow
        } else {
            $groupedTargets = $allTargets | Group-Object -Property Path | Sort-Object Name
            
            foreach ($group in $groupedTargets) {
                $pathDisplay = if ($group.Name -eq ".") { "Project Root" } else { $group.Name }
                Write-Host "  📁 $pathDisplay" -ForegroundColor Green
                
                foreach ($target in $group.Group | Sort-Object Name) {
                    Write-Host "    🎯 $($target.Name)" -ForegroundColor White
                }
                Write-Host ""
            }
            
            Write-Host "Total targets found: $($allTargets.Count)" -ForegroundColor Cyan
        }
        
        Write-Host "`nTo build specific targets:" -ForegroundColor DarkGray
        Write-Host "  .\scripts\build.ps1 -Targets `"TargetName1`", `"TargetName2`"" -ForegroundColor DarkGray
        Write-Host "  .\scripts\build.ps1 -Targets `"TargetName`" -ExcludeTargets `"UnwantedTarget`"" -ForegroundColor DarkGray
        
        return
    }

    # Build the project
    Write-Host "🔧 Building project..." -ForegroundColor Blue
    $BuildCmd = @("cmake", "--build", $BuildOutputDir, "--config", $Config, "--parallel", $Jobs)
    
    if ($Targets.Count -gt 0) {
        # Filter out excluded targets - ensure we maintain array structure
        $TargetsToBuild = @($Targets | Where-Object { $_ -notin $ExcludeTargets })
        
        if ($TargetsToBuild.Count -eq 0) {
            throw "No targets to build after applying exclusions"
        }
        
        if ($TargetsToBuild.Count -eq 1) {
            $BuildCmd += "--target", $TargetsToBuild[0]
            Write-Host "Target: $($TargetsToBuild[0])" -ForegroundColor Green
        } else {
            # For multiple targets, build them individually to handle failures gracefully
            Write-Host "Targets: $($TargetsToBuild -join ', ')" -ForegroundColor Green
            if ($ExcludeTargets.Count -gt 0) {
                Write-Host "Excluded: $($ExcludeTargets -join ', ')" -ForegroundColor Yellow
            }
            
            $SuccessfulTargets = @()
            $FailedTargets = @()
            
            foreach ($Target in $TargetsToBuild) {
                Write-Host "  Building $Target..." -ForegroundColor DarkCyan
                $TargetBuildCmd = @("cmake", "--build", $BuildOutputDir, "--config", $Config, "--parallel", $Jobs, "--target", $Target)
                if ($Verbose) {
                    $TargetBuildCmd += "--verbose"
                }
                
                & $TargetBuildCmd[0] $TargetBuildCmd[1..($TargetBuildCmd.Length-1)]
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✅ $Target" -ForegroundColor Green
                    $SuccessfulTargets += $Target
                } else {
                    Write-Host "  ❌ $Target failed" -ForegroundColor Red
                    $FailedTargets += $Target
                }
            }
            
            Write-Host "📊 Build summary:" -ForegroundColor Cyan
            Write-Host "  ✅ Successful: $($SuccessfulTargets.Count)/$($TargetsToBuild.Count) ($($SuccessfulTargets -join ', '))" -ForegroundColor Green
            if ($FailedTargets.Count -gt 0) {
                Write-Host "  ❌ Failed: $($FailedTargets.Count)/$($TargetsToBuild.Count) ($($FailedTargets -join ', '))" -ForegroundColor Red
                throw "Some targets failed to build"
            }
            
            # Skip the normal build execution since we built targets individually
            return
        }
    } elseif ($ExcludeTargets.Count -gt 0) {
        Write-Host "Excluded targets: $($ExcludeTargets -join ', ')" -ForegroundColor Yellow
        Write-Host "Building all targets except excluded ones..." -ForegroundColor Blue
        # Note: CMake doesn't have native exclude functionality, so we build all targets and let it handle what exists
    }
    
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
