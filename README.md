# cmake-initializer
A modern, cross-platform CMake project template designed to streamline C++ project setup. This boilerplate emphasizes **simplicity**, best practices, modularity, and ease of use across Windows/Linux/macOS environments.

## Documentation

* [CMake Variables Reference](./docs/CMAKE_VARIABLES.md) - All available configuration options
* [Build & Test Scripts](./scripts/README.md) - Cross-platform PowerShell scripts with mandatory preset-based builds
* [Preset-Based Configuration Features](./docs/PRESET_FEATURES.md)
* [Testing Frameworks Integration](./docs/TESTING_SUMMARY.md)
* [CI/CD Pipeline Guide](./docs/CICD_PIPELINE.md)
* [CDash Integration Guide](./docs/CDASH_INTEGRATION.md.md)
* [Emscripten Auto-Installation](./docs/EMSCRIPTEN_AUTO_INSTALL.md) - Zero-setup WebAssembly builds

## Features

- **Cross-Platform Ready**: Preconfigured presets for Windows (MSVC/Clang), Unix-like (GCC/Clang), and WebAssembly (Emscripten)
- **Modern CMake**: Targets-based structure with `CMakePresets.json` configuration and mandatory preset system
- **Modular Architecture**: Clean separation with `register_executable()`, `register_library()`, `register_test()`, and `register_project()`
- **Built-in Quality Tools**: `.clang-format`, `.clang-tidy`, sanitizers, and interprocedural optimization
- **Project Infrastructure**: Automatic version/config generation, CPM/XRepo package management, hardened build options
- **Sample Projects**: 5 ready-to-use examples covering basic usage, libraries, packages, testing, and WebAssembly
- **Environment Integration**: `.env` file support for secrets and configuration management

## Quick Start

### Prerequisites
- CMake ≥ 3.21
- C++ Compiler (MSVC, GCC, Clang, or Emscripten)
- Ninja (recommended) or Visual Studio 2022 (Windows)
- Docker (optional, for containerized development)

### Basic Usage

**Native Development:**
```powershell
# Clone and navigate
git clone https://github.com/<user>/<your_new_repo>.git
cd <your_new_repo>

# Build with mandatory preset specification
.\scripts\build.ps1 -Preset windows-msvc-release -Static
.\scripts\test.ps1 -Preset test-windows-msvc-release -VerboseOutput
.\scripts\install.ps1 -Preset windows-msvc-release
```

**Containerized Development:**
```bash
# Cross-platform builds using Docker
docker -f ./docker/docker-compose.dev.yml compose --profile linux-gcc run --rm project-linux-gcc build
docker -f ./docker/docker-compose.dev.yml compose --profile linux-clang run --rm project-linux-clang test
```

**Manual CMake:**
```bash
# Direct CMake usage
cmake -S ./project -B "build" --preset unixlike-gcc-release
cmake --build "build" --target install
ctest --test-dir "build"
```

### Available Presets
- **Windows**: `windows-msvc-debug/release`, `windows-clang-debug/release`
- **Unix-like**: `unixlike-gcc-debug/release`, `unixlike-clang-debug/release`
- **WebAssembly**: `emscripten-debug/release`

### Configuration Options
- **Preset-Based**: All scripts require mandatory `-Preset` parameter for consistent builds
- **Simple Mode**: `DEV_MODE=ON` (dev tools), `RELEASE_MODE=ON` (optimizations)
- **Advanced**: Fine-grained control over sanitizers, static analysis, warnings
- **Environment**: Use `.env` files for secrets and configuration values

See [docs/CMAKE_VARIABLES.md](./docs/CMAKE_VARIABLES.md) for complete configuration reference.

### Customizing Your Project
Edit [ProjectMetadata.cmake](./project/ProjectMetadata.cmake) to set project name, version, and description.

## Environment Variables & Secrets

Load secrets and configuration at configure time using `.env` files:

```cmake
register_executable(MyApp ENVIRONMENT production)
# Loads .env and .env.production from your CMakeLists.txt directory
```

**Note:** Never commit `.env` files containing secrets to public repositories.

## Development Workflows

### Local Development
- Use PowerShell scripts for native builds: `.\scripts\build.ps1 -Preset <preset>`
- Leverage IDE integration with CMakePresets.json
- Run quality tools: clang-format, clang-tidy, sanitizers

### Containerized Development
- Multi-compiler testing: GCC and Clang environments
- Consistent cross-platform builds with automatic preset injection

### CI/CD Integration
- GitHub Actions workflows for native
- Automatic testing across platforms with fail-fast strategy
- Container registry publishing and security scanning
- See [CI/CD Pipeline Guide](./docs/CICD_PIPELINE.md) for details

## Contributing

Contributions welcome! Please:
* Follow existing code style (enforced by .clang-format)
* Test changes with multiple presets and platforms
* Update documentation accordingly

## License
MIT License - See [LICENSE](./LICENSE) file for details.