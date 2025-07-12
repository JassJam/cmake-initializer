#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Cross-platform install script for cmake-initializer projects

.DESCRIPTION
    Unified PowerShell script that installs the project on Windows, Linux, and macOS.
    Handles installation of built artifacts to system or custom locations with support
    for component-based installation and comprehensive error checking.
    
    This script provides dry-run capabilities, detailed installation reporting, and
    handles conflicts with existing installations. It works with cmake-initializer's
    preset-based build system and automatically detects build artifacts.

.PARAMETER Config
    Build configuration to install. Must be either 'Debug' or 'Release'.
    The configuration must match what was previously built.
    Default: Release
    
    This determines which build artifacts to install - debug versions include
    debug symbols while release versions are optimized.

.PARAMETER Prefix
    Installation prefix directory where files will be installed. Can be an absolute
    or relative path. If not specified, defaults to './install' in the project directory.
    Default: ./install (relative to project directory)
    
    Examples:
    - Windows: "C:\Program Files\MyProject"
    - Linux: "/usr/local" or "~/myproject"
    - macOS: "/Applications/MyProject"

.PARAMETER Component
    Specific component to install instead of installing everything. This allows
    selective installation of only certain parts of the project.
    Default: (empty - install all components)
    
    Common components include 'Runtime', 'Development', 'Documentation'.
    Available components depend on how the project configures CMake install rules.

.PARAMETER BuildDir
    Build directory containing the artifacts to install. Must contain a valid
    CMake build with install rules configured.
    Default: "out"
    
    This should match the build directory used during compilation.

.PARAMETER Verbose
    Enable verbose installation output showing detailed file operations, sizes,
    and installation paths. Useful for debugging installation issues.
    Default: false

.PARAMETER DryRun
    Show what would be installed without actually installing anything. This is
    useful for previewing installation operations and verifying paths.
    Default: false
    
    When enabled, shows detailed information about files that would be installed
    and their destination paths without making any changes to the system.

.PARAMETER Force
    Force installation even if target files already exist. This will overwrite
    existing files without confirmation prompts.
    Default: false (shows confirmation for conflicts)

.EXAMPLE
    .\scripts\install.ps1
    
    Install with default settings (Release configuration to ./install directory).
    This is the most common usage for local development installations.

.EXAMPLE
    .\scripts\install.ps1 -Prefix "C:\Program Files\MyProject" -Verbose
    
    Install to a system location with detailed output. Useful for creating
    system-wide installations with full visibility into the process.

.EXAMPLE
    .\scripts\install.ps1 -DryRun -Verbose
    
    Show what would be installed with detailed information without actually
    installing. Perfect for previewing installation operations.

.EXAMPLE
    .\scripts\install.ps1 -Config Debug -Component Runtime -Force
    
    Install only the runtime component from a debug build, overwriting any
    existing files. Useful for selective updates of specific components.

.NOTES
    Requires a successful build to be completed first. The script verifies that
    build artifacts exist before attempting installation.
    
    Installation paths and permissions may require administrator/sudo privileges
    depending on the target directory chosen.
    
    The script provides detailed reporting of installation size and file counts
    after successful completion.

.LINK
    https://github.com/01Pollux/cmake-initializer
#>
param(
    [ValidateSet("Debug", "Release")]
    [string]$Config = "Release",
    [string]$Prefix = "",
    [string]$Component = "",
    [string]$BuildDir = "out",
    [switch]$Verbose,
    [switch]$DryRun,
    [switch]$Force
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
} elseif (-not (Test-Path (Join-Path $ProjectRoot "CMakePresets.json"))) {
    throw "Could not find CMakePresets.json in $ProjectRoot or $ProjectRoot\project"
}

# Platform detection
$Platform = if ($PSVersionTable.PSVersion.Major -ge 6) {
    if ($IsWindows) { "Windows" }
    elseif ($IsLinux) { "Linux" }
    else { "macOS" }
} else {
    if ($env:OS -eq "Windows_NT") { "Windows" } else { "Unix" }
}

Write-Host "📦 cmake-initializer Install Script" -ForegroundColor Cyan
Write-Host "Platform: $Platform" -ForegroundColor Green
Write-Host "Configuration: $Config" -ForegroundColor Green

# Determine preset based on platform and configuration
$Preset = ""
if ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows) {
    $Preset = "windows-msvc-$($Config.ToLower())"
} elseif ($PSVersionTable.PSVersion.Major -lt 6 -and $env:OS -eq "Windows_NT") {
    $Preset = "windows-msvc-$($Config.ToLower())"
} else {
    $Preset = "unixlike-gcc-$($Config.ToLower())"
}

Write-Host "Using preset: $Preset" -ForegroundColor Green

# Change to project directory
Push-Location $ProjectDir

try {
    # Determine the actual build directory based on preset structure
    $ActualBuildPath = Join-Path $ProjectDir "$BuildDir/build/$Preset"
    
    # Verify build directory exists
    if (-not (Test-Path $ActualBuildPath)) {
        throw "Build directory '$ActualBuildPath' not found. Run build script first."
    }

    # Check if project is configured
    $CMakeCachePath = Join-Path $ActualBuildPath "CMakeCache.txt"
    if (-not (Test-Path $CMakeCachePath)) {
        throw "Project not configured. Run build script first."
    }

    # Determine default prefix if not specified
    if (-not $Prefix) {
        if ($Platform -eq "Windows") {
            $Prefix = Join-Path $ProjectDir "install"
        } else {
            $Prefix = Join-Path $ProjectDir "install"
        }
    }

    Write-Host "Installation prefix: $Prefix" -ForegroundColor Green

    # Build install command
    $InstallArgs = @("--install", $ActualBuildPath, "--config", $Config)

    if ($Prefix) {
        $InstallArgs += "--prefix"
        $InstallArgs += $Prefix
    }

    if ($Component) {
        $InstallArgs += "--component"
        $InstallArgs += $Component
        Write-Host "Component: $Component" -ForegroundColor Green
    }

    if ($Verbose) {
        $InstallArgs += "--verbose"
    }

    # Show what will be installed
    if ($DryRun -or $Verbose) {
        Write-Host "Installation command:" -ForegroundColor Yellow
        Write-Host "  cmake $($InstallArgs -join ' ')" -ForegroundColor DarkGray
        Write-Host ""
    }

    if ($DryRun) {
        Write-Host "🔍 Dry run mode - showing what would be installed:" -ForegroundColor Yellow
        
        # Try to get install manifest
        $ManifestPath = Join-Path $ActualBuildPath "install_manifest.txt"
        if (Test-Path $ManifestPath) {
            $Manifest = Get-Content $ManifestPath
            Write-Host "Files that would be installed:" -ForegroundColor Cyan
            foreach ($File in $Manifest) {
                Write-Host "  📄 $File" -ForegroundColor DarkCyan
            }
        } else {
            Write-Host "Install manifest not found. Run a build first to see detailed install list." -ForegroundColor Yellow
        }
        
        return
    }

    # Check if prefix directory exists and handle conflicts
    if ((Test-Path $Prefix) -and -not $Force) {
        $ExistingFiles = Get-ChildItem -Recurse $Prefix -ErrorAction SilentlyContinue
        if ($ExistingFiles) {
            Write-Host "⚠️  Installation prefix '$Prefix' already contains files." -ForegroundColor Yellow
            $Confirmation = Read-Host "Continue with installation? This may overwrite existing files. (y/N)"
            if ($Confirmation -notmatch "^[Yy]") {
                Write-Host "❌ Installation cancelled by user" -ForegroundColor Yellow
                return
            }
        }
    }

    # Create prefix directory if it doesn't exist
    if (-not (Test-Path $Prefix)) {
        Write-Host "📁 Creating installation directory: $Prefix" -ForegroundColor Blue
        New-Item -ItemType Directory -Path $Prefix -Force | Out-Null
    }

    # Run the installation
    Write-Host "📦 Installing project..." -ForegroundColor Blue
    $InstallCmd = @("cmake") + $InstallArgs
    
    if ($Verbose) {
        Write-Host "Command: $($InstallCmd -join ' ')" -ForegroundColor DarkGray
    }
    
    & $InstallCmd[0] $InstallCmd[1..($InstallCmd.Length-1)]
    if ($LASTEXITCODE -ne 0) {
        throw "Installation failed with exit code $LASTEXITCODE"
    }

    Write-Host "✅ Installation completed successfully!" -ForegroundColor Green
    
    # Show installation summary
    if (Test-Path $Prefix) {
        $InstalledFiles = Get-ChildItem -Recurse $Prefix | Where-Object { -not $_.PSIsContainer }
        $InstalledSize = ($InstalledFiles | Measure-Object -Property Length -Sum).Sum
        $InstalledSizeMB = [math]::Round($InstalledSize / 1MB, 2)
        
        Write-Host "📊 Installation summary:" -ForegroundColor Cyan
        Write-Host "  Location: $Prefix" -ForegroundColor Cyan
        Write-Host "  Files: $($InstalledFiles.Count)" -ForegroundColor Cyan
        Write-Host "  Size: ${InstalledSizeMB} MB" -ForegroundColor Cyan
        
        if ($Verbose) {
            Write-Host "  Installed files:" -ForegroundColor Cyan
            foreach ($File in $InstalledFiles | Select-Object -First 10) {
                $RelativePath = $File.FullName.Replace($Prefix, "")
                Write-Host "    📄 $RelativePath" -ForegroundColor DarkCyan
            }
            if ($InstalledFiles.Count -gt 10) {
                Write-Host "    ... and $($InstalledFiles.Count - 10) more files" -ForegroundColor DarkCyan
            }
        }
    }

} catch {
    Write-Host "❌ Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
