# Automatic EMSDK Installation

The cmake-initializer now supports **zero-setup WebAssembly builds** with automatic EMSDK installation.

## How It Works

1. **Detection**: When you run `.\scripts\build.ps1 -Compiler emscripten`, the system checks for EMSDK
2. **Auto-Install**: If EMSDK is not found, it automatically:
   - Downloads EMSDK to `.emsdk/` directory
   - Installs the latest Emscripten version
   - Activates the environment
   - Configures CMake to use the local installation
3. **Build**: Proceeds with WebAssembly compilation using the auto-installed EMSDK

## File Structure

After automatic installation, your project will have:

```
your-project/
├── out/
│   ├── install/emscripten-release/
│   │   ├── YourApp.js         # JavaScript glue code
│   │   ├── YourApp.wasm       # WebAssembly binary
│   │   └── YourApp.html       # Generated web page
│   └── build/emscripten-release/
│       ├── YourApp.js         # JavaScript glue code
│       ├── YourApp.wasm       # WebAssembly binary
│       └── YourApp.html       # Generated web page
└── project/
    └── .emsdk/                # Local EMSDK installation (git-ignored)
```

## Configuration

The automatic installation is controlled by:

```cmake
# In CMakePresets.json or cmake command line
"ENABLE_EMSDK_AUTO_INSTALL": true  # Default: ON
```

Disable it if you prefer manual EMSDK management:

```bash
.\scripts\build.ps1 -Compiler emscripten -Config Release -DENABLE_EMSDK_AUTO_INSTALL=OFF
```
