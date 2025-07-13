#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Cross-platform test script for cmake-initializer projects

.DESCRIPTION
    Unified PowerShell script that runs tests on Windows, Linux, and macOS.
    Supports comprehensive test execution with detailed reporting, parallel execution,
    and integration with various testing frameworks including doctest, Catch2, Google Test, and Boost.Test.
    
    This script automatically detects the project structure, discovers available tests,
    and provides detailed output including test results, coverage information, and
    performance metrics. It integrates seamlessly with cmake-initializer's preset-based
    build system and CI/CD pipelines.

.PARAMETER Config
    Build configuration to test. Must be either 'Debug' or 'Release'.
    Default: Release
    
    Debug builds may include additional test assertions and debugging information,
    while Release builds test the optimized code paths that will be deployed.

.PARAMETER Preset
    CMake preset to use for testing. If not specified, automatically determined based on
    platform and configuration:
    - Windows: test-windows-msvc-debug/release, test-windows-clang-debug/release
    - Unix-like: test-unixlike-gcc-debug/release, test-unixlike-clang-debug/release

.PARAMETER Compiler
    Specific compiler to use for testing. Must be one of: 'msvc', 'clang', 'gcc'.
    If not specified, uses platform default (MSVC on Windows, GCC on Unix-like).
    
    This parameter changes the CMake preset to use the specified compiler for testing.
    - msvc: Only available on Windows, uses Visual Studio compiler
    - clang: Uses Clang/Clang-cl compiler
    - gcc: Uses GNU Compiler Collection

.PARAMETER BuildDir
    Build directory containing the test executables. Should match the directory
    used during the build process.
    Default: "out" (matches cmake-initializer preset structure)

.PARAMETER Parallel
    Number of parallel test jobs to run simultaneously. Higher values can speed up
    test execution on multi-core systems but may cause resource contention.
    Default: Number of CPU cores detected on the system

.PARAMETER Filter
    Regular expression pattern to filter which tests to run. Only tests matching
    the pattern will be executed. Useful for running specific test suites or
    categories during development.
    Default: (empty - run all tests)
    
    Examples:
    - "Unit.*" - Run only unit tests
    - ".*Integration.*" - Run only integration tests
    - "MyClass.*" - Run tests for specific class

.PARAMETER Timeout
    Maximum time in seconds to wait for each individual test to complete.
    Tests exceeding this limit will be terminated and marked as failed.
    Default: 300 (5 minutes)

.PARAMETER Repeat
    Number of times to repeat the test suite. Useful for detecting flaky tests
    or performance regressions. Each iteration runs the complete test suite.
    Default: 1

.PARAMETER Output
    Output format for test results. Supported formats:
    - 'default': Standard CTest output
    - 'verbose': Detailed test output with individual test results
    - 'junit': JUnit XML format for CI/CD integration
    - 'json': JSON format for programmatic processing
    Default: default

.PARAMETER Coverage
    Enable code coverage reporting. Requires gcov/llvm-cov to be available.
    Generates coverage reports showing which parts of the code are tested.
    Default: false
    
    Coverage reports are generated in HTML format in the build directory.

.PARAMETER Valgrind
    Run tests under Valgrind for memory error detection (Linux/macOS only).
    Helps detect memory leaks, buffer overflows, and other memory-related issues.
    Default: false
    
    Note: Significantly increases test execution time but provides valuable
    debugging information for memory-related issues.

.PARAMETER StopOnFailure
    Stop test execution immediately when the first test fails. Useful during
    development to get quick feedback on test failures.
    Default: false (continue running all tests)

.PARAMETER Verbose
    Enable verbose test output showing detailed execution information, including
    individual test results, timing information, and system details.
    Default: false

.EXAMPLE
    .\scripts\test.ps1
    
    Run all tests with default settings (Release configuration, auto-detected preset).
    This is the most common usage for validating the project.

.EXAMPLE
    .\scripts\test.ps1 -Config Debug -Verbose
    
    Run all tests in Debug configuration with verbose output.
    Useful during development to see detailed test execution information.

.EXAMPLE
    .\scripts\test.ps1 -Filter "Unit.*" -Parallel 4
    
    Run only unit tests using 4 parallel jobs.
    Good for focused testing of specific components during development.

.EXAMPLE
    .\scripts\test.ps1 -Coverage -Output junit
    
    Run tests with code coverage and generate JUnit XML output.
    Ideal for CI/CD pipelines that need coverage reports and test result integration.

.EXAMPLE
    .\scripts\test.ps1 -Repeat 10 -StopOnFailure
    
    Run the test suite 10 times, stopping at the first failure.
    Useful for detecting intermittent test failures or race conditions.

.NOTES
    Requires CMake 3.21+ and CTest. Test executables must be built before running this script.
    For best results, ensure tests are built with the same configuration being tested.

.LINK
    https://github.com/01Pollux/cmake-initializer
#>
param(
    [ValidateSet("Debug", "Release")]
    [string]$Config = "Release",
    [string]$Preset = "",
    [ValidateSet("msvc", "clang", "gcc", "")]
    [string]$Compiler = "",
    [string]$BuildDir = "out",
    [int]$Parallel = 0,
    [string]$Filter = "",
    [int]$Timeout = 300,
    [int]$Repeat = 1,
    [ValidateSet("default", "verbose", "junit", "json")]
    [string]$Output = "default",
    [switch]$Coverage,
    [switch]$Valgrind,
    [switch]$StopOnFailure,
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

# Determine number of parallel jobs if not specified
if ($Parallel -eq 0) {
    $Parallel = [Environment]::ProcessorCount
}

# Platform detection
$Platform = if ($PSVersionTable.PSVersion.Major -ge 6) {
    if ($IsWindows) { "Windows" }
    elseif ($IsLinux) { "Linux" }
    else { "macOS" }
} else {
    if ($env:OS -eq "Windows_NT") { "Windows" } else { "Unix" }
}

Write-Host "🧪 cmake-initializer Test Script" -ForegroundColor Cyan
Write-Host "Platform: $Platform" -ForegroundColor Green
Write-Host "Configuration: $Config" -ForegroundColor Green

# Determine preset if not specified
if (-not $Preset) {
    if ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows) {
        $Preset = "windows-msvc-$($Config.ToLower())"
    } elseif ($PSVersionTable.PSVersion.Major -lt 6 -and $env:OS -eq "Windows_NT") {
        $Preset = "windows-msvc-$($Config.ToLower())"
    } else {
        $Preset = "unixlike-gcc-$($Config.ToLower())"
    }
}

# Override preset based on compiler selection
if ($Compiler) {
    switch ($Compiler.ToLower()) {
        "msvc" {
            if (-not ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows) -and -not ($PSVersionTable.PSVersion.Major -lt 6 -and $env:OS -eq "Windows_NT")) {
                throw "MSVC compiler is only available on Windows"
            }
            $Preset = "windows-msvc-$($Config.ToLower())"
        }
        "clang" {
            if (($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows) -or ($PSVersionTable.PSVersion.Major -lt 6 -and $env:OS -eq "Windows_NT")) {
                $Preset = "windows-clang-$($Config.ToLower())"
            } else {
                $Preset = "unixlike-clang-$($Config.ToLower())"
            }
        }
        "gcc" {
            $Preset = "unixlike-gcc-$($Config.ToLower())"
        }
    }
    Write-Host "Compiler: $Compiler" -ForegroundColor Green
}

Write-Host "Test Preset: $Preset" -ForegroundColor Green

# Change to project directory
Push-Location $ProjectDir

try {
    # Determine build directory from preset - use workspace root with configurable BuildDir
    $FullBuildDir = Join-Path $ProjectRoot "$BuildDir/build/$Preset"
    
    if (-not (Test-Path $FullBuildDir)) {
        throw "Build directory not found: $FullBuildDir. Please run build script first."
    }

    Write-Host "Build directory: $FullBuildDir" -ForegroundColor DarkGray

    # Check if tests are available
    $TestFiles = Get-ChildItem -Path $FullBuildDir -Recurse -Include "*.exe", "*test*" -File | Where-Object { $_.Name -match "test" }
    if ($TestFiles.Count -eq 0) {
        Write-Warning "No test executables found in build directory. Make sure tests are built with BUILD_TESTING=ON."
    }

    # Build CTest command
    $CTestCmd = @("ctest", "--test-dir", $FullBuildDir, "--build-config", $Config)
    
    # Add parallel execution
    $CTestCmd += @("--parallel", $Parallel)
    
    # Add timeout
    $CTestCmd += @("--timeout", $Timeout)
    
    # Add test filter if specified
    if ($Filter) {
        $CTestCmd += @("-R", $Filter)
        Write-Host "Test filter: $Filter" -ForegroundColor Yellow
    }
    
    # Add repeat count
    if ($Repeat -gt 1) {
        $CTestCmd += @("--repeat", "until-pass:$Repeat")
        Write-Host "Repeat count: $Repeat" -ForegroundColor Yellow
    }
    
    # Configure output format
    switch ($Output) {
        "verbose" {
            $CTestCmd += @("--verbose", "--output-on-failure")
        }
        "junit" {
            $JUnitFile = Join-Path $FullBuildDir "test-results.xml"
            $CTestCmd += @("--output-junit", $JUnitFile)
            Write-Host "JUnit output: $JUnitFile" -ForegroundColor DarkGray
        }
        "json" {
            $JsonFile = Join-Path $FullBuildDir "test-results.json"
            $CTestCmd += @("--output-json", $JsonFile)
            Write-Host "JSON output: $JsonFile" -ForegroundColor DarkGray
        }
        "default" {
            $CTestCmd += @("--output-on-failure")
        }
    }
    
    # Add stop on failure
    if ($StopOnFailure) {
        $CTestCmd += @("--stop-on-failure")
    }
    
    # Add coverage support
    if ($Coverage) {
        Write-Host "📊 Enabling code coverage..." -ForegroundColor Blue
        $CTestCmd += @("-T", "Coverage")
    }
    
    # Add Valgrind support (Linux/macOS only)
    if ($Valgrind) {
        if ($Platform -eq "Windows") {
            Write-Warning "Valgrind is not available on Windows. Skipping memory check."
        } else {
            Write-Host "🔍 Enabling Valgrind memory check..." -ForegroundColor Blue
            $CTestCmd += @("-T", "MemCheck")
        }
    }
    
    # Add verbose output
    if ($Verbose) {
        $CTestCmd += @("--verbose")
        Write-Host "Command: $($CTestCmd -join ' ')" -ForegroundColor DarkGray
    }
    
    # Run tests
    Write-Host "🏃 Running tests..." -ForegroundColor Blue
    $StartTime = Get-Date
    
    & $CTestCmd[0] $CTestCmd[1..($CTestCmd.Length-1)]
    $TestExitCode = $LASTEXITCODE
    
    $EndTime = Get-Date
    $Duration = $EndTime - $StartTime
    
    # Report results
    if ($TestExitCode -eq 0) {
        Write-Host "✅ All tests passed!" -ForegroundColor Green
    } else {
        Write-Host "❌ Some tests failed (exit code: $TestExitCode)" -ForegroundColor Red
    }
    
    Write-Host "⏱️  Test duration: $($Duration.ToString('mm\:ss'))" -ForegroundColor Cyan
    
    # Show coverage results if enabled
    if ($Coverage) {
        $CoverageDir = Join-Path $FullBuildDir "Coverage"
        if (Test-Path $CoverageDir) {
            Write-Host "📊 Coverage report generated in: $CoverageDir" -ForegroundColor Cyan
        }
    }
    
    # Show memory check results if enabled
    if ($Valgrind -and $Platform -ne "Windows") {
        $MemCheckDir = Join-Path $FullBuildDir "DynamicAnalysis"
        if (Test-Path $MemCheckDir) {
            Write-Host "🔍 Memory check report generated in: $MemCheckDir" -ForegroundColor Cyan
        }
    }
    
    # Exit with the same code as CTest
    exit $TestExitCode

} catch {
    Write-Host "❌ Test execution failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
