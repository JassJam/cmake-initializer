# CI/CD Pipeline Guide

## Pipeline Overview

The CI/CD pipeline follows a **Test → Build → Publish** strategy to provide fast feedback and efficient resource usage:

```
1. Test Stage (Parallel across all platforms)
   ↓
2. Build Stage (Clean production builds)
   ↓ 
3. Publish Stage (Artifact distribution)
```

## Pipeline Stages

**Supported Platforms:**
- Linux (Ubuntu) with GCC and Clang
- macOS with GCC and Clang  
- Windows with MSVC and Clang-cl

### 1. Test Stage (Fast Failure Detection)
Runs first to catch issues early and save resources:

- **Parallel Execution**: Tests run simultaneously on all supported platforms
- **Test Reporting**: Generates JUnit XML test reports for GitHub integration

### 2. Build Stage (Clean Production Builds)
Runs only after all tests pass across all platforms:

- **Cross-Platform**: Builds on all supported platforms and compilers
- **Optimized Artifacts**: Generates release-optimized binaries
- **Install Targets**: Creates proper installation packages

### 3. Publish Stage (Release Distribution)
Runs only on tagged releases after successful test and build stages:

- **Tagged Releases**: Triggers only when pushing git tags
- **Artifact Publishing**: Publishes release artifacts to GitHub Releases
- **Version Management**: Uses git tag as release version

## Workflow Triggers

The pipeline automatically triggers in the following scenarios:

### Push Events
- **Branches**: `main` and `dev` branches
- **Behavior**: Runs test and build stages, skips publish

### Pull Request Events  
- **Target Branches**: PRs to `main` and `dev` branches
- **Behavior**: Runs test and build stages for validation

### Tag Events
- **Pattern**: Any git tag (e.g., `v1.0.0`, `1.2.3`)
- **Behavior**: Runs full pipeline including publish stage

## Local Testing

You can replicate the CI pipeline locally for development and debugging:

### Test-Focused Build (Like CI Test Stage)
```bash
# Configure with testing enabled
cmake -S ./project -B build-test --preset <your-preset> -DBUILD_TESTING=ON

# Build all targets including tests
cmake --build build-test --config Release

# Run tests with detailed output
cd build-test
ctest --build-config Release --output-on-failure --verbose

# Run with JUnit XML output (like CI)
ctest --build-config Release --output-junit test-results.xml
```

### Production Build (Like CI Build Stage)
```bash
# Configure for production (no tests)
cmake -S ./project -B build-prod --preset <your-preset> -DBUILD_TESTING=OFF

# Build and install
cmake --build build-prod --config Release --target install

# Verify clean artifacts
ls build-prod/install/
```

### Available Presets
```bash
# Windows
--preset windows-msvc-release
--preset windows-clang-release

# Linux/Unix
--preset unixlike-gcc-release  
--preset unixlike-clang-release

# macOS (same as Unix)
--preset unixlike-gcc-release
--preset unixlike-clang-release
```
