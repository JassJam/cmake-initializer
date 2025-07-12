# Testing Framework Integration

Modern C++ testing framework integration with automatic setup and discovery.

## Overview

This CMake boilerplate provides seamless integration for popular C++ testing frameworks with minimal configuration. Choose your preferred framework and get automatic test discovery, configuration, and execution.

> **Configuration Reference**: See [CMAKE_VARIABLES.md](./CMAKE_VARIABLES.md) for all available build and testing configuration variables.

## Supported Frameworks

| Framework | Description | Auto-Discovery | CTest Integration |
|-----------|-------------|----------------|-------------------|
| [**DocTest**](https://github.com/doctest/doctest) | Fast, lightweight testing | ✅ | ✅ |
| [**Catch2**](https://github.com/catchorg/Catch2) | Modern, header-only framework | ✅ | ✅ |
| [**Google Test**](https://github.com/google/googletest) | Industry-standard framework | ✅ | ✅ |
| [**Boost.Test**](https://github.com/boostorg/test) | Comprehensive testing suite | ✅ | ✅ |

## Key Features

### **Simple API**
- **One-time registration**: `register_test_framework(framework_name)`
- **Auto-discovery**: Finds `test_*.cpp` files automatically
- **Seamless integration**: Works with CTest out of the box

### **Flexible Configuration**
- **Framework selection**: Choose any supported framework
- **Custom test patterns**: Override default discovery patterns
- **Build configuration**: Debug/Release builds supported

## Quick Start

### 1. Framework Registration
Add once in your main `CMakeLists.txt`:

```cmake
# Choose your testing framework
register_test_framework(doctest)   # Fast and lightweight
# register_test_framework(catch2)  # Modern C++ features
# register_test_framework(gtest)   # Industry standard
# register_test_framework(boost)   # Comprehensive suite
```

### 2. Test Creation
Add tests anywhere in your project:

```cmake
# In any subdirectory CMakeLists.txt
register_test(MyComponentTests)  # Auto-discovers test_*.cpp files
```

### 3. Build and Execute

**Using Scripts (Recommended):**
```powershell
# Build and run tests in one workflow
.\scripts\build.ps1 -Config Release
.\scripts\test.ps1 -Config Release -Verbose

# Development testing with coverage
.\scripts\build.ps1 -Config Debug
.\scripts\test.ps1 -Config Debug -Coverage -Output verbose
```

**Manual Commands (Alternative):**
```bash
# Configure with testing enabled
cmake -S project -B build --preset <your-preset>

# Build including tests
cmake --build build

# Run all tests
ctest --test-dir build --output-on-failure
```

## Project Structure

### Recommended Layout
```
project/
├── CMakeLists.txt          # register_test_framework() here
├── src/
│   └── my_component.cpp
├── include/
│   └── my_component.hpp
└── tests/
    ├── CMakeLists.txt      # register_test() here
    ├── test_component.cpp  # Auto-discovered
    └── test_utils.cpp      # Auto-discovered
```

### Core Implementation Files
- `project/cmake/modules/ProjectBoilerplate.cmake` - Core testing functions
- `project/samples/hello_testing_frameworks/` - Complete working example

## Advanced Usage

### Custom Test Discovery
```cmake
# Override default test file patterns
register_test(MyTests
    SOURCES "custom_test_*.cpp" "integration_*.cpp"
)

# Explicit file listing
register_test(MyTests
    SOURCES "specific_test.cpp" "another_test.cpp"
)
```

### Framework-Specific Configuration
```cmake
# Framework-specific options can be set before registration
set(DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN ON)
register_test_framework(doctest)
```

## Advanced Testing Features

### Script-Based Testing Options

The `test.ps1` script provides comprehensive testing capabilities:

```powershell
# Run specific test categories
.\scripts\test.ps1 -Filter "Unit.*" -Parallel 4

# Generate coverage reports
.\scripts\test.ps1 -Coverage -Output html

# Stress testing for flaky test detection
.\scripts\test.ps1 -Repeat 10 -StopOnFailure

# Memory testing (Linux/macOS)
.\scripts\test.ps1 -Valgrind -Timeout 600

# CI/CD integration
.\scripts\test.ps1 -Output junit -Coverage -Parallel 8
```
