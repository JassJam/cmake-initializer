# CMake Boilerplate - Simplified Usage Guide

## Quick Start

### Basic Project Setup
```cmake
# In your main CMakeLists.txt
cmake_minimum_required(VERSION 3.21)
project(MyProject VERSION 1.0.0)

# Include the boilerplate
include(cmake/modules/ProjectBoilerplate.cmake)

# Optional: Set up testing framework (call once)
# Use DEFAULT_TEST_FRAMEWORK for automatic test framework selection
register_test_framework("doctest")  # or "catch2", "gtest", "boost"
```

## Core Functions

### **1. Executables** - `register_executable()`

Create executable targets with automatic source discovery and modern CMake best practices.

#### Basic Usage
```cmake
# Minimal setup - auto-discovers src/*.cpp and include/
register_executable(MyApp INSTALL)

# Custom source/include directories
register_executable(MyApp 
    SOURCE_DIR custom_src 
    INCLUDE_DIR custom_headers
    INSTALL
)
```

#### Advanced Configuration
```cmake
# Full control with visibility scopes
register_executable(MyApp
    SOURCES 
        PRIVATE "src/main.cpp" "src/internal.cpp"
        PUBLIC "src/api.cpp"
    INCLUDES 
        PRIVATE "src/internal" 
        PUBLIC "include"
        INTERFACE "interface/headers"
    LIBRARIES 
        PRIVATE "internal_lib" 
        PUBLIC "shared_lib"
        INTERFACE "header_only_lib"
    COMPILE_DEFINITIONS 
        PRIVATE "INTERNAL_BUILD=1"
        PUBLIC "API_VERSION=2"
    COMPILE_OPTIONS 
        PRIVATE "-fno-rtti"
        PUBLIC "-fPIC"
    COMPILE_FEATURES 
        PRIVATE "cxx_std_17"
        PUBLIC "cxx_std_20"
    DEPENDENCIES  # Auto-loads Dependencies.cmake if available
    INSTALL
)
```

### **2. Libraries** - `register_library()`

Build static, shared, or header-only libraries with proper export configuration.

#### Basic Usage
```cmake
# Static library (default)
register_library(MyLib INSTALL)

# Shared library with auto-export
register_library(MyLib SHARED INSTALL)

# Header-only library (interface only)
register_library(MyLib INTERFACE INSTALL)
```

#### Advanced Configuration
```cmake
# Comprehensive library with proper export handling
register_library(MyLib SHARED
    SOURCE_DIR "src"
    INCLUDE_DIR "include"
    SOURCES 
        PRIVATE "src/impl.cpp" "src/internal.cpp"
        PUBLIC "src/api.cpp"
    INCLUDES 
        PRIVATE "src/internal"
        PUBLIC "include"
        INTERFACE "interface"
    LIBRARIES 
        PRIVATE "boost::system" 
        PUBLIC "fmt::fmt"
        INTERFACE "header_only_dep"
    COMPILE_DEFINITIONS 
        PRIVATE "BUILDING_MYLIB"
        PUBLIC "MYLIB_API=1"
        INTERFACE "MYLIB_HEADER_ONLY"
    EXPORT_MACRO "MYLIB_EXPORT"  # Automatic export symbols
    PROPERTIES 
        "VERSION" "1.0.0"
        "SOVERSION" "1"
    DEPENDENCIES
    INSTALL
)
```

### **3. Project Organization** - `register_project()`

Streamline project structure with batch operations and consistent organization.

#### Batch Operations
```cmake
# Add multiple subdirectories
register_project(SUBDIRS 
    "core" 
    "utilities" 
    "plugins"
)

# Create multiple executables in current directory
register_project(EXECUTABLES 
    "app1" 
    "app2" 
    "admin_tool"
)

# Create multiple libraries with consistent settings
register_project(LIBRARIES 
    "core_lib" 
    "util_lib" 
    "plugin_interface"
)

# Combined operations for complex projects
register_project(
    NAME "MyProject"
    SUBDIRS "core" "utilities"
    EXECUTABLES "main_app"
    LIBRARIES "shared_lib"
)
```

### **4. Testing** - `register_test()`

Automatic test discovery and framework integration with minimal configuration.

#### Basic Testing Setup
```cmake
# One-time framework registration (in main CMakeLists.txt)
register_test_framework("doctest")  # or catch2, gtest, boost

# Simple test with auto-discovery
register_test(MyTests 
    LIBRARIES PRIVATE MyLib
)

# Custom test configuration
register_test(UnitTests
    SOURCES PRIVATE "test/unit_tests.cpp" "test/helpers.cpp"
    LIBRARIES PRIVATE MyLib test_utils
    INCLUDES PRIVATE "test/include"
    INSTALL
)
```

#### Advanced Testing Features
```cmake
# Comprehensive test setup with full control
register_test(IntegrationTests
    SOURCE_DIR "integration_tests"
    SOURCES 
        PRIVATE "test/integration_main.cpp"
        PRIVATE "test/mock_services.cpp"
    INCLUDES 
        PRIVATE "test/mocks"
        PRIVATE "test/fixtures"
    LIBRARIES 
        PRIVATE MyLib database_lib
        INTERFACE test_framework_extensions
    COMPILE_DEFINITIONS 
        PRIVATE "TEST_MODE=1"
        PRIVATE "MOCK_SERVICES=1"
    COMPILE_OPTIONS 
        PRIVATE "-g" "-O0"  # Debug symbols, no optimization
    PROPERTIES 
        "TIMEOUT" "30"
        "WORKING_DIRECTORY" "${CMAKE_CURRENT_SOURCE_DIR}/test_data"
    INSTALL
)
```

## Visibility Control System

### Understanding Visibility
- **PRIVATE**: Only visible to this target, not propagated to dependents
- **PUBLIC**: Visible to this target AND propagated to dependents
- **INTERFACE**: Only propagated to dependents, not used by this target

### Practical Examples

#### Library Design Pattern
```cmake
# Well-designed library with proper visibility
register_library(NetworkLib SHARED
    SOURCES 
        PRIVATE "src/internal_socket.cpp"    # Implementation details
        PRIVATE "src/connection_pool.cpp"    # Internal functionality
        PUBLIC "src/network_api.cpp"         # Public API implementation
    INCLUDES 
        PRIVATE "src/internal"               # Internal headers
        PUBLIC "include"                     # Public API headers
        INTERFACE "interface"                # Headers for dependents only
    LIBRARIES 
        PRIVATE "openssl"                    # Implementation dependency
        PUBLIC "boost::system"               # Public API dependency
        INTERFACE "header_only_protocol"     # Header-only protocol
    COMPILE_DEFINITIONS 
        PRIVATE "BUILDING_NETWORK_LIB"       # Build-time flag
        PUBLIC "NETWORK_LIB_VERSION=2"       # API version
        INTERFACE "USE_NETWORK_LIB"          # Flag for users
    EXPORT_MACRO "NETWORK_API"
    INSTALL
)
```

#### Application Pattern
```cmake
# Application using the library
register_executable(MyNetworkApp
    SOURCES PRIVATE "src/main.cpp" "src/app_logic.cpp"
    INCLUDES PRIVATE "src/internal"
    LIBRARIES 
        PRIVATE NetworkLib                   # Gets PUBLIC+INTERFACE from NetworkLib
        PRIVATE "app_specific_lib"           # Only for this app
    COMPILE_DEFINITIONS 
        PRIVATE "APP_VERSION=1.0"
    INSTALL
)
```

## Configuration Options

> **Complete Reference**: See [CMAKE_VARIABLES.md](./CMAKE_VARIABLES.md) for the complete list of all available configuration variables and their detailed descriptions.

### Quick Configuration Modes

#### Development Mode (Default)
```cmake
# Enable comprehensive development tools
set(DEV_MODE ON)  # Enables sanitizers, static analysis, warnings as errors
```

#### Production Mode
```cmake
# Enable optimizations for release builds
set(RELEASE_MODE ON)  # Enables IPO/LTO, performance optimizations
```

### Fine-Grained Control
```cmake
# Individual feature control
set(ENABLE_SANITIZERS ON)          # Address/UB sanitizers
set(ENABLE_STATIC_ANALYSIS ON)     # clang-tidy and cppcheck
set(ENABLE_WARNINGS_AS_ERRORS ON)  # Treat warnings as errors
set(ENABLE_IPO ON)                 # Link-time optimization
set(ENABLE_UNITY_BUILD ON)         # Unity builds
set(ENABLE_PCH ON)                 # Precompiled headers
```

## Real-World Examples

### Complete Project Structure
```cmake
# Main CMakeLists.txt
cmake_minimum_required(VERSION 3.21)
project(MyProject VERSION 1.0.0)

include(cmake/modules/ProjectBoilerplate.cmake)

# Set up testing
register_test_framework("doctest")

# Add subdirectories
register_project(SUBDIRS
    "core"
    "utilities"
    "applications"
    "tests"
)
```

### Core Library (core/CMakeLists.txt)
```cmake
register_library(MyCore SHARED
    SOURCES 
        PRIVATE "src/implementation.cpp"
        PUBLIC "src/api.cpp"
    INCLUDES 
        PRIVATE "src/internal"
        PUBLIC "include"
    LIBRARIES 
        PRIVATE "boost::filesystem"
        PUBLIC "spdlog::spdlog"
    COMPILE_DEFINITIONS 
        PRIVATE "BUILDING_CORE"
        PUBLIC "CORE_API_VERSION=1"
    EXPORT_MACRO "CORE_EXPORT"
    INSTALL
)
```

### Utility Library (utilities/CMakeLists.txt)
```cmake
register_library(MyUtilities STATIC
    INCLUDES PUBLIC "include"
    LIBRARIES 
        PUBLIC MyCore
        PRIVATE "internal_helpers"
    INSTALL
)
```

### Application (applications/CMakeLists.txt)
```cmake
register_executable(MyApp
    SOURCES PRIVATE "src/main.cpp"
    LIBRARIES 
        PRIVATE MyCore
        PRIVATE MyUtilities
    INSTALL
)
```

### Tests (tests/CMakeLists.txt)
```cmake
register_test(CoreTests
    SOURCES PRIVATE "test_core.cpp"
    LIBRARIES PRIVATE MyCore
)

register_test(UtilityTests
    SOURCES PRIVATE "test_utilities.cpp"
    LIBRARIES PRIVATE MyUtilities
)

register_test(IntegrationTests
    SOURCES PRIVATE "test_integration.cpp"
    LIBRARIES PRIVATE MyCore MyUtilities
)
```

## Best Practices

### 1. Library Design
- Use `PRIVATE` for implementation details
- Use `PUBLIC` for dependencies that appear in your public API
- Use `INTERFACE` for header-only dependencies or flags for users

### 2. Executable Design
- Most dependencies should be `PRIVATE` for executables
- Use `PUBLIC` only when the executable is meant to be linked to

### 3. Testing
- Always use `PRIVATE` for test dependencies
- Link to the libraries you're testing as `PRIVATE`
- Use test framework's recommended linking approach

### 4. Project Organization
- Keep related functionality in subdirectories
- Use `register_project()` for batch operations
- Maintain clear dependency hierarchies

## Migration Guide

### From Traditional CMake
```cmake
# Traditional CMake
add_executable(MyApp src/main.cpp)
target_include_directories(MyApp PRIVATE include)
target_link_libraries(MyApp PRIVATE MyLib)
target_compile_definitions(MyApp PRIVATE APP_VERSION=1)
install(TARGETS MyApp DESTINATION bin)

# With boilerplate
register_executable(MyApp
    SOURCES PRIVATE "src/main.cpp"
    INCLUDES PRIVATE "include"
    LIBRARIES PRIVATE MyLib
    COMPILE_DEFINITIONS PRIVATE "APP_VERSION=1"
    INSTALL
)
```

## Dependency Management System

### Using External Dependencies with CPM

When you use the `DEPENDENCIES` flag with any register function, it automatically loads a `Dependencies.cmake` file from the current directory and calls `target_load_dependencies()` to handle external packages.

#### Setting Up Dependencies
Create a `Dependencies.cmake` file in your project directory:

```cmake
# Dependencies.cmake
function(target_load_dependencies target)
    target_add_dependency(${target}
        PACKAGES
            spdlog
                URL         https://github.com/gabime/spdlog/archive/refs/tags/v1.15.2.zip
                URL_HASH    SHA256=d91ab0e16964cedb826e65ba1bed5ed4851d15c7b9453609a52056a94068c020
                OPTIONS     "SPDLOG_BUILD_SHARED ON"
            
            fmt
                GIT_REPOSITORY  https://github.com/fmtlib/fmt.git
                GIT_TAG         10.2.1
                OPTIONS         "FMT_INSTALL ON"
            
            boost
                VERSION         1.82.0
                LINK_TARGETS    "Boost::system PRIVATE" "Boost::filesystem PUBLIC"
    )
endfunction()
```

#### Using Dependencies in Your Project
```cmake
# In your CMakeLists.txt
register_executable(MyApp
    SOURCES PRIVATE "src/main.cpp"
    DEPENDENCIES  # This loads Dependencies.cmake and calls target_load_dependencies()
    INSTALL
)
```

### target_add_dependency() Function

The `target_add_dependency()` function provides a unified interface for managing external dependencies using CPM (C++ Package Manager).

#### Basic Package Options
- **URL**: Direct download from archive URL
- **GIT_REPOSITORY + GIT_TAG**: Git repository with specific tag/branch/commit
- **GITHUB_REPOSITORY**: Shorthand for GitHub repositories (e.g., "owner/repo")
- **VERSION**: Specific version to download
- **URL_HASH**: SHA256 hash for URL downloads (recommended for security)

#### Advanced Options
- **OPTIONS**: CMake options to pass to the package build
- **LINK_TARGETS**: Specific targets to link (overrides auto-detection)
- **LINK_TYPE**: Default link type (PRIVATE, PUBLIC, INTERFACE)
- **INSTALL_TYPE**: Installation behavior (NONE, SHARED, ALL)
- **COMPONENT**: Installation component name
- **DOWNLOAD_ONLY**: Only download, don't build or link

#### Example with Advanced Options
```cmake
function(target_load_dependencies target)
    target_add_dependency(${target}
        PACKAGES
            # Header-only library
            nlohmann_json
                VERSION         3.11.2
                LINK_TYPE       INTERFACE
                INSTALL_TYPE    NONE
            
            # Custom linking
            opencv
                VERSION         4.8.0
                LINK_TARGETS    "opencv_core PRIVATE" "opencv_imgproc PRIVATE"
                INSTALL_TYPE    ALL
                COMPONENT       "opencv-runtime"
            
            # Build configuration
            protobuf
                VERSION         3.21.12
                OPTIONS         "protobuf_BUILD_TESTS OFF" "protobuf_BUILD_EXAMPLES OFF"
                LINK_TARGETS    "protobuf::libprotobuf PRIVATE"
    )
endfunction()
```

### Supported Package Patterns

The system automatically detects common target naming patterns:
- Direct target name (e.g., `spdlog`)
- Namespaced targets (e.g., `spdlog::spdlog`)
- Alternative naming (e.g., `spdlog_spdlog`)

For packages with non-standard targets, use `LINK_TARGETS` to specify explicitly.

### Integration with register_* Functions

All register functions support the `DEPENDENCIES` flag:

```cmake
# Executable with dependencies
register_executable(MyApp DEPENDENCIES INSTALL)

# Library with dependencies  
register_library(MyLib SHARED DEPENDENCIES INSTALL)

# Test with dependencies
register_test(MyTests DEPENDENCIES)
```

## Best Practices

### 📁 Recommended Project Structure
```
MyProject/
├── CMakeLists.txt              # Main project file
├── cmake/
│   └── modules/
│       └── ProjectBoilerplate.cmake
├── Dependencies.cmake          # Optional: package dependencies
├── src/                        # Source files
├── include/                    # Public headers
├── tests/                      # Test files
└── examples/                   # Usage examples
```

### Common Patterns
```cmake
# Typical library setup
register_library(MyLib SHARED
    INCLUDE_DIR "include"
    LIBRARIES PUBLIC "external_api" PRIVATE "internal_dep"
    INSTALL
)

# Typical executable setup
register_executable(MyApp
    LIBRARIES PRIVATE MyLib
    INSTALL
)

# Typical test setup
register_test(MyLibTests
    LIBRARIES PRIVATE MyLib
)
```

## **Next Steps**: 
- See [CMAKE_VARIABLES.md](./CMAKE_VARIABLES.md) for complete configuration options
- Check [PRESET_FEATURES.md](./PRESET_FEATURES.md) for preset-based development
- Review [TESTING_SUMMARY.md](./TESTING_SUMMARY.md) for testing framework details
