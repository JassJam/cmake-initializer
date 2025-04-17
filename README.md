# cmake-initializer
A modern, cross-platform CMake project template designed to streamline C++ project setup. This boilerplate emphasizes best practices, modularity, and ease of use across Windows/Linux/macOS environments.

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
[ProjectOptions.cmake](./project/base/project_options/ProjectOptions.cmake) exposes these settings (modify before first configure)

### Customizing for Your Project
[ProjectMetadata.cmake](./ProjectMetadata.cmake) exposes these configuration to specialize your project.

### Contributing

Contributions are welcome! Please follow:
* Follow existing code style (enforced by .clang-format)
* Test changes with multiple presets
* Update documentation accordingly

### License
MIT License - See [LICENSE](./LICENSE) file for details.