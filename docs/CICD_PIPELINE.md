# CI/CD Pipeline Guide

## Pipeline Overview

The CI/CD pipeline follows a **Test → Build → Publish** strategy to provide fast feedback and efficient resource usage:

```
1. Test Stage
   ↓
2. Build Stage 
   ↓ 
3. Publish Stage
```

## Pipeline Stages

**Supported Platforms:**
- Linux (Ubuntu) with GCC and Clang
- macOS with GCC and Clang  
- Windows with MSVC and Clang-cl
- Emscripten (WASM)

### 1. Test Stage
Runs first to catch issues early and save resources:

- **Parallel Execution**: Tests run simultaneously on all supported platforms
- **Test Reporting**: Generates JUnit XML test reports for GitHub integration

### 2. Build Stage
Runs only after all tests pass across all platforms:

- **Cross-Platform**: Builds on all supported platforms and compilers
- **Optimized Artifacts**: Generates release-optimized binaries
- **Install Targets**: Creates proper installation packages

### 3. Publish Stage
Runs only on tagged releases after successful test and build stages:

- **Tagged Releases**: Triggers only when pushing git tags
- **Artifact Publishing**: Publishes release artifacts to GitHub Releases
- **Version Management**: Uses git tag as release version

## Local Testing

You can replicate the CI pipeline locally for development and debugging:

### Test-Focused Workflow

**Using Scripts:**
```powershell
# Build with testing enabled and run tests
.\scripts\build.ps1 -Preset <your-preset>
.\scripts\test.ps1 -Preset <your-preset> -Output junit
```

### Production Build (Like CI Build Stage)

**Using Scripts:**
```powershell
# Clean build for production
.\scripts\clean.ps1 -All -Force
.\scripts\build.ps1 -Config Release
.\scripts\install.ps1 -Config Release
```

### Development Workflow

**Complete Development Cycle:**
```powershell
# Full development workflow with scripts
.\scripts\build.ps1 -Preset <your-preset> 
.\scripts\test.ps1 -Preset <your-preset> -Coverage  # Run tests with coverage
```
