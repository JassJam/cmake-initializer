#!/usr/bin/env pwsh
#requires -version 7.0

$ErrorActionPreference = "Stop"

# Docker entrypoint script for cmake-initializer (PowerShell version)

function Show-Usage {
    Write-Host "🐳 " -NoNewline -ForegroundColor Blue
    Write-Host "project Docker Container" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available commands:" -ForegroundColor White
    Write-Host "  🔨 build [options]     - Build projects using cmake-initializer" -ForegroundColor Green
    Write-Host "  🧪 test [options]      - Run tests" -ForegroundColor Green  
    Write-Host "  🧹 clean [options]     - Clean build artifacts" -ForegroundColor Green
    Write-Host "  📦 install [options]   - Install built projects" -ForegroundColor Green
    Write-Host "  💻 shell               - Start interactive shell" -ForegroundColor Green
    Write-Host "  ❓ --help              - Show this help" -ForegroundColor Green
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  docker run project build --preset unixlike-gcc-release"
    Write-Host "  docker run project test --verbose"
    Write-Host "  docker run project clean"
    Write-Host "  docker run -it project shell"
    Write-Host ""
    Write-Host "For detailed script help:" -ForegroundColor Yellow
    Write-Host "  docker run project build --help"
    Write-Host "  docker run project test --help"
}

# Handle different commands
$command = $args[0]
$remainingArgs = $args[1..$args.Length]

# Helper function to inject preset parameter based on environment
function Add-PresetParameter {
    param([string[]]$Arguments)
    
    if ($env:COMPILER -and $Arguments -notcontains "-Preset") {
        # Map compiler environment to preset
        $preset = switch ($env:COMPILER.ToLower()) {
            "clang" { "unixlike-clang-release" }
            "gcc"   { "unixlike-gcc-release" }
            "msvc"  { "windows-msvc-release" }
            "emscripten" { "emscripten-release" }
            default { "unixlike-gcc-release" }
        }
        
        # Check if Config is Debug to use debug preset
        if ($Arguments -contains "-Config" -and $Arguments -contains "Debug") {
            $preset = $preset -replace "release", "debug"
        }
        
        $result = @("-Preset", $preset) + $Arguments
        Write-Host "🔧 Using preset from environment: $preset (compiler: $env:COMPILER)" -ForegroundColor Yellow
        Write-Host "Debug: Final arguments: $($result -join ' ')" -ForegroundColor DarkGray
        return $result
    }
    return $Arguments
}

switch ($command) {
    "build" {
        $scriptArgs = Add-PresetParameter $remainingArgs
        Write-Host "Debug: Executing: ./scripts/build.ps1 $($scriptArgs -join ' ')" -ForegroundColor DarkGray
        & pwsh -c "./scripts/build.ps1 $($scriptArgs -join ' ')"
        exit $LASTEXITCODE
    }
    "test" {
        $scriptArgs = Add-PresetParameter $remainingArgs
        & pwsh -c "./scripts/test.ps1 $($scriptArgs -join ' ')"
        exit $LASTEXITCODE
    }
    "clean" {
        # Clean doesn't need preset parameter
        & pwsh -c "./scripts/clean.ps1 $($remainingArgs -join ' ')"
        exit $LASTEXITCODE
    }
    "install" {
        $scriptArgs = Add-PresetParameter $remainingArgs
        & pwsh -c "./scripts/install.ps1 $($scriptArgs -join ' ')"
        exit $LASTEXITCODE
    }
    "shell" {
        & pwsh
        exit $LASTEXITCODE
    }
    { $_ -in @("--help", "help", "", $null) } {
        Show-Usage
    }
    default {
        Write-Host "❌ Unknown command: $command" -ForegroundColor Red
        Write-Host ""
        Show-Usage
        exit 1
    }
}
