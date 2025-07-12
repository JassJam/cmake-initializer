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

### Test-Focused Workflow (Like CI Test Stage)

**Using Scripts (Recommended):**
```powershell
# Build with testing enabled and run tests
.\scripts\build.ps1 -Config Release
.\scripts\test.ps1 -Config Release -Verbose

# Run with JUnit XML output
.\scripts\test.ps1 -Config Release -Output junit
```

**Manual Commands (Alternative):**
```bash
# Configure with testing enabled
cmake -S ./project -B build-test --preset <your-preset> -DBUILD_TESTING=ON

# Build all targets including tests
cmake --build build-test --config Release

# Run tests with detailed output
cd build-test
ctest --build-config Release --output-on-failure --verbose
```

### Production Build (Like CI Build Stage)

**Using Scripts (Recommended):**
```powershell
# Clean build for production
.\scripts\clean.ps1 -All -Force
.\scripts\build.ps1 -Config Release -Static
.\scripts\install.ps1 -Config Release
```

**Manual Commands (Alternative):**
```bash
# Configure for production
cmake -S ./project -B build-prod --preset <your-preset>

# Build and install
cmake --build build-prod --config Release
cmake --install build-prod --config Release
```

### Development Workflow

**Complete Development Cycle:**
```powershell
# Full development workflow with scripts
.\scripts\clean.ps1              # Clean previous builds
.\scripts\build.ps1 -Config Debug # Build in debug mode
.\scripts\test.ps1 -Config Debug -Coverage  # Run tests with coverage
```

**Cross-Compiler Testing:**
```powershell
# Test multiple compilers like CI does
.\scripts\build.ps1 -Compiler gcc -Config Release
.\scripts\test.ps1 -Compiler gcc -Config Release

.\scripts\build.ps1 -Compiler clang -Config Release
.\scripts\test.ps1 -Compiler clang -Config Release
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

## Advanced Testing Features

The test script provides comprehensive testing capabilities that mirror CI/CD requirements:

### CI/CD Integration Features
```powershell
# Generate reports for CI/CD pipelines
.\scripts\test.ps1 -Output junit -Coverage -Parallel 8

# Stress testing for stability validation
.\scripts\test.ps1 -Repeat 5 -StopOnFailure

# Memory testing (Linux/macOS CI environments)
.\scripts\test.ps1 -Valgrind -Timeout 600
```

### Cross-Platform Testing Matrix
```powershell
# Windows testing matrix
.\scripts\test.ps1 -Compiler msvc -Config Release
.\scripts\test.ps1 -Compiler clang -Config Release

# Unix-like testing matrix (Linux/macOS)
.\scripts\test.ps1 -Compiler gcc -Config Release  
.\scripts\test.ps1 -Compiler clang -Config Release
```

### Test Filtering and Categorization
```powershell
# Run specific test categories
.\scripts\test.ps1 -Filter "Unit.*" -Verbose
.\scripts\test.ps1 -Filter "Integration.*" -Output junit

# Performance and load testing
.\scripts\test.ps1 -Filter "Performance.*" -Timeout 900
```

## CI/CD Reporting and Metrics

### Test Result Formats
- **JUnit XML**: `.\scripts\test.ps1 -Output junit` - For Jenkins, GitHub Actions, etc.
- **JSON**: `.\scripts\test.ps1 -Output json` - For custom reporting tools
- **Verbose**: `.\scripts\test.ps1 -Output verbose` - Detailed console output

### Coverage Reports
```powershell
# Generate coverage reports
.\scripts\test.ps1 -Coverage -Output junit

# Coverage reports are generated in:
# - HTML format: build/Coverage/
# - XML format: build/coverage.xml (if supported)
```

### Performance Metrics
```powershell
# Parallel testing performance
.\scripts\test.ps1 -Parallel 16 -Verbose  # Show timing per test

# Memory usage analysis (Linux/macOS)
.\scripts\test.ps1 -Valgrind -Output verbose
```
