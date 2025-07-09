# cmake-initializer
A modern, cross-platform CMake project template designed to streamline C++ project setup. This boilerplate emphasizes **simplicity**, best practices, modularity, and ease of use across Windows/Linux/macOS environments.

## Less boilerplate

See [SIMPLIFIED_USAGE.md](./docs/SIMPLIFIED_USAGE.md) for complete usage guide.

## Features

- **Cross-Platform Ready**: Preconfigured presets for:
  - Windows: MSVC & Clang-Cl (Debug/Release)
  - Unix-like: GCC & Clang (Debug/Release)
- **Modern CMake**: Targets-based structure with `CMakePresets.json` configuration.
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
- See [SIMPLIFIED_USAGE.md](./docs/SIMPLIFIED_USAGE.md) for complete options

### Customizing for Your Project
Edit [ProjectMetadata.cmake](./project/ProjectMetadata.cmake) to set your project name, version, and description.

### Contributing

Contributions are welcome! Please follow:
* Follow existing code style (enforced by .clang-format)
* Test changes with multiple presets
* Update documentation accordingly

### License
MIT License - See [LICENSE](./LICENSE) file for details.