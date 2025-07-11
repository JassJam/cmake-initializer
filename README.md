# cmake-initializer
A modern, cross-platform CMake project template designed to streamline C++ project setup. This boilerplate emphasizes **simplicity**, best practices, modularity, and ease of use across Windows/Linux/macOS environments.

## Less boilerplate

* [Simplified Usage Guide](./docs/SIMPLIFIED_USAGE.md)
* [Preset-Based Configuration Features](./docs/PRESET_FEATURES.md)
* [Testing Frameworks Integration](./docs/TESTING_SUMMARY.md)
* [CI/CD Pipeline Guide](./docs/CICD_PIPELINE.md)

## Features

- **Cross-Platform Ready**: Preconfigured presets for:
  - Windows: MSVC & Clang-Cl (Debug/Release)
  - Unix-like: GCC & Clang (Debug/Release)
- **Modern CMake**: Targets-based structure with `CMakePresets.json` configuration.
- **Modular Architecture**: Clean separation of concerns with focused modules:
  - `register_executable()`: Comprehensive executable creation with visibility control
  - `register_library()`: Full library support (SHARED/STATIC/INTERFACE) with export handling
  - `register_test()`: Integrated test framework support (doctest, Catch2, gtest, Boost.Test)
  - `register_project()`: Simplified project setup and batch operations
- **Built-in Quality Tools**:
  - `.clang-format` & `.clang-tidy` integration
  - Sanitizers support (ASan, UBSan, etc.)
  - Interprocedural Optimization (IPO)
- **Project Infrastructure**:
  - Automatic version/config generation
  - Package management via CPM/XRepo
  - Hardened build options
- **Sample Projects**: 4 ready-to-use examples:
  - Hello World
  - Static/Shared Libraries
  - External Package Usage
  - Testing Frameworks (doctest, Catch2, gtest, Boost.Test) 

## Quick Start

### Prerequisites
- CMake ≥ 3.21
- C++ Compiler
- Ninja (recommended) or Visual Studio 2022 (Windows)

### Basic Usage
```bash
# Clone the repository
git clone https://github.com/<user>/<your_new_repo>.git

# Create build & install directory
mkdir -p build; mkdir -p install

# Configure project
cmake -S ./project -B "build" --preset <preset> -DCMAKE_INSTALL_PREFIX="install"

# Build & install (optional)
cmake --build "build" --target "install"

# Run tests
ctest --build-target "build"
```

### Key Configuration Options
- **Simple Mode**: `DEV_MODE=ON` (enables all dev tools), `RELEASE_MODE=ON` (optimizations)
- **Advanced**: Fine-grained control over sanitizers, static analysis, warnings, etc.
- See [SIMPLIFIED_USAGE.md](./docs/SIMPLIFIED_USAGE.md) for complete options and examples

### Customizing for Your Project
Edit [ProjectMetadata.cmake](./project/ProjectMetadata.cmake) to set your project name, version, and description.

## CI/CD Pipeline

This boilerplate includes a comprehensive GitHub Actions workflow with fail-fast testing strategy. The pipeline runs tests first for early failure detection, then builds clean production artifacts only if all tests pass.

**Key Features:**
- **Test → Build → Publish** workflow for optimal efficiency
- **Fail-fast testing** across all platforms (Linux, macOS, Windows)
- **Clean production artifacts** with `BUILD_TESTING=OFF` on release builds
- **Automatic publishing** on tagged releases
- **CTest Dashboard Integration**: Automatic test result uploads when configured with repository secrets:
  - `CTEST_DASHBOARD_SITE`: Your dashboard hostname
  - `CTEST_DASHBOARD_LOCATION`: Upload endpoint path
  - `CTEST_SUBMIT_URL_PRESET`: Complete URL for CTest submission
  - `CTEST_TEST_TIMEOUT_PRESET`: Test timeout in seconds

For detailed information, see the [CI/CD Pipeline Guide](./docs/CICD_PIPELINE.md).

The pipeline automatically triggers on pushes to `main`/`dev` branches and pull requests, ensuring code quality with efficient resource usage.

### Contributing

Contributions are welcome! Please follow:
* Follow existing code style (enforced by .clang-format)
* Test changes with multiple presets
* Update documentation accordingly

### License
MIT License - See [LICENSE](./LICENSE) file for details.