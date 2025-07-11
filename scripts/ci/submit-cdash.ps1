#!/usr/bin/env pwsh
# CI CDash Submission Script

param(
    [Parameter(Mandatory=$true)]
    [string]$BuildDir,
    
    [Parameter(Mandatory=$true)]
    [string]$SourceDir,
    
    [Parameter(Mandatory=$true)]
    [string]$BuildName,
    
    [string]$CdashSite = $env:CTEST_DASHBOARD_SITE,
    [string]$CdashLocation = $env:CTEST_DASHBOARD_LOCATION,
    [string]$AuthToken = $env:CDASH_AUTH_TOKEN,
    [string]$DropMethod = $env:CTEST_DROP_METHOD,
    [string]$DashboardModel = $env:CTEST_DASHBOARD_MODEL
)

# Validate required parameters
if ([string]::IsNullOrEmpty($CdashSite)) {
    Write-Warning "CTEST_DASHBOARD_SITE not set - skipping CDash submission"
    exit 0
}

if ([string]::IsNullOrEmpty($CdashLocation)) {
    Write-Warning "CTEST_DASHBOARD_LOCATION not set - skipping CDash submission"
    exit 0
}

# Set defaults
if ([string]::IsNullOrEmpty($DropMethod)) {
    $DropMethod = "https"
}

if ([string]::IsNullOrEmpty($DashboardModel)) {
    $DashboardModel = "Continuous"
}

Write-Host "=== CI CDash Submission ==="
Write-Host "Build Directory: $BuildDir"
Write-Host "Source Directory: $SourceDir"
Write-Host "Build Name: $BuildName"
Write-Host "CDash Site: $CdashSite"
Write-Host "CDash Location: $CdashLocation"
Write-Host "Dashboard Model: $DashboardModel"
Write-Host "Auth Token: $($AuthToken.Length -gt 0 ? 'Present' : 'Not provided')"

# Validate directories exist
if (-not (Test-Path $BuildDir)) {
    Write-Error "Build directory does not exist: $BuildDir"
    exit 1
}

if (-not (Test-Path $SourceDir)) {
    Write-Error "Source directory does not exist: $SourceDir"
    exit 1
}

# Resolve to absolute paths
$BuildDir = Resolve-Path $BuildDir
$SourceDir = Resolve-Path $SourceDir

# Set up environment variables for CTest script
$env:CTEST_SOURCE_DIRECTORY = $SourceDir
$env:CTEST_BINARY_DIRECTORY = $BuildDir
$env:CTEST_BUILD_NAME = $BuildName
$env:CTEST_SITE = $env:RUNNER_NAME ?? $env:COMPUTERNAME ?? "CI"
$env:CTEST_DROP_SITE = $CdashSite
$env:CTEST_DROP_LOCATION = $CdashLocation
$env:CTEST_DROP_METHOD = $DropMethod
$env:CTEST_DASHBOARD_MODEL = $DashboardModel

# Set auth token if provided
if ($AuthToken.Length -gt 0) {
    $env:CTEST_CDASH_AUTH_TOKEN = $AuthToken
    Write-Host "CDash authentication configured"
} else {
    Write-Host "No authentication token provided - submitting without auth"
}

# Change to build directory and run CTest script
Push-Location $BuildDir -StackName "CDashSubmission"
$CTestScript = Join-Path $SourceDir "CTestScript.cmake"

if (-not (Test-Path $CTestScript)) {
    Write-Error "CTest script not found: $CTestScript"
    exit 1
}

Write-Host "`n=== Running CTest Submission ==="
ctest -S $CTestScript -V

Push-Location -StackName "CDashSubmission"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ CDash submission completed successfully"
} else {
    Write-Warning "CDash submission failed with exit code: $LASTEXITCODE"
    # Don't fail the CI build for CDash submission failures
    exit 0
}
