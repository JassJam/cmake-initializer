# Simplified CMake Usage Guide

This boilerplate now provides simplified functions to reduce verbosity while maintaining all functionality.

## Quick Reference

### Simple Executable
```cmake
# Basic executable (auto-discovers src/*.cpp and include/)
simple_executable(MyApp INSTALL)

# With external dependencies
simple_executable(MyApp DEPENDENCIES INSTALL)

# With custom libraries
simple_executable(MyApp LIBRARIES MyLib SomeOtherLib INSTALL)

# Custom source/include directories
simple_executable(MyApp 
    SOURCE_DIR custom_src 
    INCLUDE_DIR custom_headers 
    INSTALL
)
```

### Simple Library
```cmake
# Static library (default)
simple_library(MyLib INSTALL)

# Shared library
simple_library(MyLib SHARED INSTALL)

# Interface library (header-only)
simple_library(MyLib INTERFACE INSTALL)

# With export macro for shared libraries
simple_library(MyLib SHARED 
    EXPORT_MACRO MY_EXPORT
    INSTALL
)
```

### Simple Project Organization
```cmake
# Add multiple subdirectories at once
simple_project(SUBDIRS subdir1 subdir2 subdir3)

# Create multiple executables in current directory
simple_project(EXECUTABLES app1 app2 app3)

# Create multiple libraries in current directory  
simple_project(LIBRARIES lib1 lib2 lib3)
```

## Configuration Options

### Simple Mode (Recommended for most users)
- `DEV_MODE=ON` (default) - Enables all development tools (sanitizers, static analysis, warnings as errors)
- `RELEASE_MODE=ON` - Enables release optimizations (IPO/LTO)

### Advanced Options (for fine-grained control)
- `ENABLE_SANITIZERS` - Address/UB sanitizers
- `ENABLE_STATIC_ANALYSIS` - clang-tidy and cppcheck  
- `ENABLE_WARNINGS_AS_ERRORS` - Treat warnings as errors
- `ENABLE_IPO` - Link-time optimization
- `ENABLE_UNITY_BUILD` - Unity builds for faster compilation
- `ENABLE_PCH` - Precompiled headers

## Advanced Usage

### Custom Sources and Headers
```cmake
simple_executable(MyApp
    SOURCES custom/main.cpp custom/utils.cpp
    INCLUDES custom/headers
    LIBRARIES external::lib
    INSTALL
)
```

### Library with Public Dependencies
```cmake
simple_library(MyLib SHARED
    PUBLIC_LIBRARIES fmt::fmt spdlog::spdlog
    INSTALL
)
```
