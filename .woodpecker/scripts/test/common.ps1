#!/usr/bin/env pwsh
# Common test logic - translated from .github/actions/test/common/action.yaml
# All config is passed via environment variables set by the calling pipeline step.
#
# Required env vars:
#   CONFIG_NAME, CONFIG_OS, CONFIG_PRESET, CONFIG_OUTPUT
#   CTEST_SITE, CTEST_LOCATION, CTEST_TEST_TIMEOUT, CTEST_DROP_METHOD,
#   CDASH_AUTH_TOKEN, CTEST_DASHBOARD_MODEL

$ErrorActionPreference = "Stop"

# Setup environment
Write-Host "=== Setting up test environment for $env:CONFIG_NAME on $env:CONFIG_OS ==="

$BUILD_DIR   = Join-Path ([System.IO.Path]::GetTempPath()) $env:CONFIG_OUTPUT "build"
$INSTALL_DIR = Join-Path ([System.IO.Path]::GetTempPath()) $env:CONFIG_OUTPUT "install"

New-Item -ItemType Directory -Force -Path $BUILD_DIR   | Out-Null
New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null

$env:BUILD_DIR   = $BUILD_DIR
$env:INSTALL_DIR = $INSTALL_DIR

# Derive version from CI_COMMIT_TAG (Woodpecker equivalent of GITHUB_REF tags)
$VERSION = $env:CI_COMMIT_TAG -replace '/', '-'
if (-not $VERSION) { $VERSION = "1.0.0-dev" }

$env:ARTIFACT_NAME = "$env:CONFIG_NAME-test-results-$VERSION"

# Build & Test
Write-Host "=== Building and Testing $env:CONFIG_NAME ==="

& "$env:CI_WORKSPACE/scripts/build.ps1" -Preset "$env:CONFIG_PRESET" -ExtraArgs @("-DBUILD_TESTING=ON")
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed with exit code: $LASTEXITCODE"
    exit $LASTEXITCODE
}

& "$env:CI_WORKSPACE/scripts/test.ps1" -Preset "$env:CONFIG_PRESET"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Tests failed with exit code: $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "Build and tests completed successfully"

# CDash submission
if ($env:CTEST_SITE -and $env:CTEST_LOCATION) {
    Write-Host "=== Submitting test results to CDash ==="
    & "$env:CI_WORKSPACE/scripts/ci/submit-cdash.ps1" `
        -BuildDir    "$env:CI_WORKSPACE/out/build/$env:CONFIG_PRESET" `
        -SourceDir   "$env:CI_WORKSPACE/project" `
        -BuildName   "$env:CONFIG_NAME-$env:CONFIG_OS" `
        -Preset      "$env:CONFIG_PRESET" `
        -CdashSite   "$env:CTEST_SITE" `
        -CdashLocation "$env:CTEST_LOCATION" `
        -AuthToken   "$env:CDASH_AUTH_TOKEN" `
        -DropMethod  "$env:CTEST_DROP_METHOD" `
        -DashboardModel "$env:CTEST_DASHBOARD_MODEL"

    if ($LASTEXITCODE -ne 0) {
        Write-Error "CDash submission failed - this usually indicates test failures"
        exit $LASTEXITCODE
    }
}

# Cleanup
Write-Host "=== Cleaning up test environment ==="
& "$env:CI_WORKSPACE/scripts/clean.ps1" -All -Force
Write-Host "Test cleanup completed."