#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

Write-Host "=== Setting up MSVC environment ==="

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) {
    Write-Error "vswhere not found. Ensure Visual Studio is installed on this runner."
    exit 1
}

$vsPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vsPath) {
    Write-Error "No Visual Studio installation with VC++ tools found."
    exit 1
}

$vcvars = Join-Path $vsPath "VC\Auxiliary\Build\vcvars64.bat"
Write-Host "Activating: $vcvars"

# Import MSVC environment variables into this PowerShell session
cmd /c "`"$vcvars`" && set" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}

if ($env:CONFIG_PRESET -like '*clang*') {
    Write-Host "=== Installing LLVM/Clang via Chocolatey ==="
    choco install llvm -y --no-progress
    # Refresh PATH so clang is visible
    $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + $env:PATH
}

Write-Host "=== Running common test logic ==="
& "$PSScriptRoot/common.ps1"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }