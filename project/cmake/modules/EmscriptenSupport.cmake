# ==============================================================================
# Emscripten Support Module
# ==============================================================================
# This module provides utility functions specifically for Emscripten/WebAssembly builds
# with automatic configuration for web deployment and optimization.

include_guard(GLOBAL)
include(GetCurrentCompiler)

# Initialize Emscripten environment if needed
function(_ensure_emscripten_ready)
    get_current_compiler(CURRENT_COMPILER)
    if(CURRENT_COMPILER STREQUAL "EMSCRIPTEN" AND ENABLE_EMSDK_AUTO_INSTALL)
        if(NOT DEFINED EMSDK_INITIALIZED)
            ensure_emsdk_available()
            set(EMSDK_INITIALIZED TRUE CACHE INTERNAL "EMSDK has been initialized")
        endif()
    endif()
endfunction()

# Configure Emscripten-specific settings for a target
# Usage:
# target_configure_emscripten(MyTarget
#     [SHELL_FILE path/to/shell.html]          # Custom HTML template for web page
#     [EXPORTED_FUNCTIONS func1 func2 ...]     # C++ functions to export to JavaScript (e.g., "_main", "_my_function")
#     [EXPORTED_RUNTIME_METHODS method1 ...]   # Emscripten runtime methods (e.g., "ccall", "cwrap", "setValue")
#     [PRELOAD_FILES file1 file2 ...]          # Files to preload into virtual filesystem at startup
#     [EMBED_FILES file1 file2 ...]            # Files to embed directly into the binary
#     [MEMORY_SIZE size_in_bytes]              # Initial memory pool size (use _parse_memory_size for units)
#     [STACK_SIZE size_in_bytes]               # Stack size (use _parse_memory_size for units)
#     [WASM]                                   # Enable WebAssembly output (default: enabled)
#     [STANDALONE_WASM]                        # Generate standalone WASM without JavaScript glue code
#     [NODE_JS]                                # Target Node.js environment instead of browser
#     [PTHREAD]                                # Enable pthread support for multithreading
#     [SIMD]                                   # Enable SIMD optimizations
#     [ASYNCIFY]                               # Enable async/await and synchronous API emulation
#     [ASSERTIONS]                             # Enable runtime assertions for debugging
#     [SAFE_HEAP]                              # Enable heap safety checks (debug mode)
#     [DEMANGLE_SUPPORT]                       # Enable C++ symbol demangling in stack traces
# )
function(target_configure_emscripten target)
    cmake_parse_arguments(ARG 
        "WASM;STANDALONE_WASM;NODE_JS;PTHREAD;SIMD;ASYNCIFY;ASSERTIONS;SAFE_HEAP;DEMANGLE_SUPPORT"
        "SHELL_FILE;MEMORY_SIZE;STACK_SIZE"
        "EXPORTED_FUNCTIONS;EXPORTED_RUNTIME_METHODS;PRELOAD_FILES;EMBED_FILES"
        ${ARGN}
    )
    
    if(NOT TARGET ${target})
        message(FATAL_ERROR "Target ${target} does not exist")
    endif()
    
    # Ensure Emscripten environment is ready
    _ensure_emscripten_ready()
    
    # Check if we're actually using Emscripten
    get_current_compiler(CURRENT_COMPILER)
    if(NOT CURRENT_COMPILER STREQUAL "EMSCRIPTEN")
        message(WARNING "target_configure_emscripten called but not using Emscripten compiler")
        return()
    endif()
    
    message(STATUS "Configuring Emscripten settings for target: ${target}")
    
    # Basic WebAssembly configuration
    if(ARG_WASM OR ARG_STANDALONE_WASM)
        target_link_options(${target} PRIVATE "SHELL:-s WASM=1")
        message(STATUS "  - WebAssembly output enabled")
    endif()
    
    # Standalone WebAssembly (no JavaScript glue code dependencies)
    if(ARG_STANDALONE_WASM)
        target_link_options(${target} PRIVATE "SHELL:-s STANDALONE_WASM=1")
        message(STATUS "  - Standalone WebAssembly mode enabled")
    endif()
    
    # Node.js environment
    if(ARG_NODE_JS)
        target_link_options(${target} PRIVATE "SHELL:-s ENVIRONMENT=node")
        message(STATUS "  - Node.js environment configured")
    endif()
    
    # Custom shell file
    if(ARG_SHELL_FILE)
        target_link_options(${target} PRIVATE "SHELL:--shell-file ${ARG_SHELL_FILE}")
        message(STATUS "  - Custom shell file: ${ARG_SHELL_FILE}")
    endif()
    
    # Exported functions
    if(ARG_EXPORTED_FUNCTIONS)
        string(JOIN "," EXPORTED_FUNCS ${ARG_EXPORTED_FUNCTIONS})
        target_link_options(${target} PRIVATE "SHELL:-s EXPORTED_FUNCTIONS=[${EXPORTED_FUNCS}]")
        message(STATUS "  - Exported functions: ${EXPORTED_FUNCS}")
    endif()
    
    # Exported runtime methods
    if(ARG_EXPORTED_RUNTIME_METHODS)
        string(JOIN "," EXPORTED_METHODS ${ARG_EXPORTED_RUNTIME_METHODS})
        target_link_options(${target} PRIVATE "SHELL:-s EXPORTED_RUNTIME_METHODS=[${EXPORTED_METHODS}]")
        message(STATUS "  - Exported runtime methods: ${EXPORTED_METHODS}")
    endif()
    
    # Preload files (loaded at startup)
    if(ARG_PRELOAD_FILES)
        string(JOIN " " PRELOAD_FILES_STR ${ARG_PRELOAD_FILES})
        target_link_options(${target} PRIVATE "SHELL:--preload-file ${PRELOAD_FILES_STR}")
        message(STATUS "  - Preloaded files: ${PRELOAD_FILES_STR}")
    endif()
    
    # Embed files (bundled into the binary)
    if(ARG_EMBED_FILES)
        string(JOIN " " EMBED_FILES_STR ${ARG_EMBED_FILES})
        target_link_options(${target} PRIVATE "SHELL:--embed-file ${EMBED_FILES_STR}")
        message(STATUS "  - Embedded files: ${EMBED_FILES_STR}")
    endif()
    
    # Memory configuration
    if(ARG_MEMORY_SIZE)
        target_link_options(${target} PRIVATE "SHELL:-s INITIAL_MEMORY=${ARG_MEMORY_SIZE}")
        message(STATUS "  - Initial memory: ${ARG_MEMORY_SIZE} bytes")
    endif()
    
    if(ARG_STACK_SIZE)
        target_link_options(${target} PRIVATE "SHELL:-s STACK_SIZE=${ARG_STACK_SIZE}")
        message(STATUS "  - Stack size: ${ARG_STACK_SIZE} bytes")
    endif()
    
    # Threading support
    if(ARG_PTHREAD)
        target_link_options(${target} PRIVATE "SHELL:-s USE_PTHREADS=1")
        target_compile_options(${target} PRIVATE "-pthread")
        message(STATUS "  - Threading support enabled")
    endif()
    
    # SIMD support
    if(ARG_SIMD)
        # SIMD is now controlled by compiler flags only, not linker settings
        target_compile_options(${target} PRIVATE "-msimd128")
        message(STATUS "  - SIMD support enabled")
    endif()
    
    # Asyncify (for synchronous APIs in async environment)
    if(ARG_ASYNCIFY)
        target_link_options(${target} PRIVATE "SHELL:-s ASYNCIFY=1")
        message(STATUS "  - Asyncify enabled")
    endif()
    
    # Development/debugging options
    if(ARG_ASSERTIONS)
        target_link_options(${target} PRIVATE "SHELL:-s ASSERTIONS=1")
        message(STATUS "  - Runtime assertions enabled")
    endif()
    
    if(ARG_SAFE_HEAP)
        target_link_options(${target} PRIVATE "SHELL:-s SAFE_HEAP=1")
        message(STATUS "  - Safe heap enabled")
    endif()
    
    if(ARG_DEMANGLE_SUPPORT)
        # DEMANGLE_SUPPORT is no longer supported in newer Emscripten versions
        # C++ symbol demangling is enabled by default
        message(STATUS "  - C++ demangling support enabled by default")
    endif()
    
    # Set appropriate file extension
    set_target_properties(${target} PROPERTIES SUFFIX ".js")
endfunction()

# Automatically configure common Emscripten settings based on build type
# Usage:
# Automatic Emscripten configuration with sensible defaults
# This provides a quick setup for most WebAssembly use cases without manual configuration
# Usage:
# target_configure_emscripten_auto(MyTarget 
#     [NODE_JS]     # Target Node.js instead of browser environment
#     [SIMD]        # Enable SIMD optimizations for better performance
#     [PTHREAD]     # Enable pthread support for multithreading
# )
# 
# Automatic settings applied:
# - WebAssembly output enabled
# - Basic runtime methods exported (ccall, cwrap)
# - Reasonable memory settings for typical applications
# - Error handling and debugging support
# - Browser-optimized settings (unless NODE_JS specified)
function(target_configure_emscripten_auto target)
    cmake_parse_arguments(ARG "NODE_JS;SIMD;PTHREAD" "" "" ${ARGN})
    
    # Ensure Emscripten environment is ready
    _ensure_emscripten_ready()
    
    get_current_compiler(CURRENT_COMPILER)
    if(NOT CURRENT_COMPILER STREQUAL "EMSCRIPTEN")
        return()
    endif()
    
    message(STATUS "Auto-configuring Emscripten for target: ${target}")
    
    # Base configuration
    set(CONFIG_ARGS WASM)
    
    # Debug vs Release configuration
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        list(APPEND CONFIG_ARGS ASSERTIONS SAFE_HEAP DEMANGLE_SUPPORT)
        target_configure_emscripten(${target} ${CONFIG_ARGS}
            MEMORY_SIZE 67108864  # 64MB for debug
            STACK_SIZE 5242880    # 5MB stack for debug
        )
    else()
        # Release optimizations
        target_link_options(${target} PRIVATE "SHELL:-O3")
        target_link_options(${target} PRIVATE "SHELL:--closure 1")
        target_configure_emscripten(${target} ${CONFIG_ARGS}
            MEMORY_SIZE 33554432  # 32MB for release
            STACK_SIZE 1048576    # 1MB stack for release
        )
    endif()
    
    # Optional features
    if(ARG_NODE_JS)
        target_configure_emscripten(${target} NODE_JS)
    endif()
    
    if(ARG_SIMD)
        target_configure_emscripten(${target} SIMD)
    endif()
    
    if(ARG_PTHREAD)
        target_configure_emscripten(${target} PTHREAD)
    endif()
endfunction()

# Create an Emscripten web page template
# Usage:
# create_emscripten_html_template(OUTPUT_FILE 
#     [TITLE "Page Title"]              # HTML page title
#     [CANVAS_ID "canvas"]              # Canvas element ID
#     [TEMPLATE_FILE path/to/template]  # Custom template file to use instead of default
# )
# 
# Template file format:
# - Use {{TITLE}} for page title substitution
# - Use {{CANVAS_ID}} for canvas element ID substitution
# - Include {{{ SCRIPT }}} where Emscripten should inject the generated JavaScript
function(create_emscripten_html_template output_file)
    cmake_parse_arguments(ARG "" "TITLE;CANVAS_ID;TEMPLATE_FILE" "" ${ARGN})
    
    if(NOT ARG_TITLE)
        set(ARG_TITLE "WebAssembly Application")
    endif()
    
    if(NOT ARG_CANVAS_ID)
        set(ARG_CANVAS_ID "canvas")
    endif()
    
    # Check if custom template file is provided and exists
    if(ARG_TEMPLATE_FILE AND EXISTS "${ARG_TEMPLATE_FILE}")
        message(STATUS "Using custom HTML template: ${ARG_TEMPLATE_FILE}")
        
        # Read the template file
        file(READ "${ARG_TEMPLATE_FILE}" HTML_CONTENT)
        
        # Perform variable substitutions
        string(REPLACE "{{TITLE}}" "${ARG_TITLE}" HTML_CONTENT "${HTML_CONTENT}")
        string(REPLACE "{{CANVAS_ID}}" "${ARG_CANVAS_ID}" HTML_CONTENT "${HTML_CONTENT}")
        
        # Validate that the template has the required {{{ SCRIPT }}} placeholder
        if(NOT HTML_CONTENT MATCHES "\\{\\{\\{ SCRIPT \\}\\}\\}")
            message(WARNING "Custom template file '${ARG_TEMPLATE_FILE}' does not contain '{{{ SCRIPT }}}' placeholder. Emscripten may not work properly.")
        endif()
        
    else()
        # Use default template if no custom template provided or file doesn't exist
        if(ARG_TEMPLATE_FILE)
            message(WARNING "Custom template file '${ARG_TEMPLATE_FILE}' not found. Using default template.")
        endif()
        
        _create_default_emscripten_template(HTML_CONTENT "${ARG_TITLE}" "${ARG_CANVAS_ID}")
    endif()
    
    # Write the final HTML content
    file(WRITE "${output_file}" "${HTML_CONTENT}")
    message(STATUS "Created Emscripten HTML template: ${output_file}")
endfunction()

# Internal function to create the default HTML template
function(_create_default_emscripten_template output_var title canvas_id)
    set(HTML_CONTENT "<!DOCTYPE html>
<html lang=\"en\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>${title}</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #fff;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            text-align: center;
        }
        h1 {
            margin-bottom: 30px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        #${canvas_id} {
            border: 2px solid #fff;
            border-radius: 8px;
            background-color: #000;
            display: block;
            margin: 20px auto;
            box-shadow: 0 8px 32px rgba(0,0,0,0.2);
        }
        .controls {
            margin: 20px 0;
        }
        button {
            padding: 12px 24px;
            margin: 8px;
            background: rgba(255,255,255,0.9);
            color: #333;
            border: none;
            border-radius: 25px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }
        button:hover {
            background: #fff;
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(0,0,0,0.3);
        }
        .output {
            background: rgba(0,0,0,0.8);
            color: #00ff41;
            padding: 20px;
            text-align: left;
            font-family: 'Courier New', monospace;
            height: 200px;
            overflow-y: auto;
            margin: 20px 0;
            border-radius: 8px;
            border: 1px solid rgba(255,255,255,0.2);
            backdrop-filter: blur(10px);
        }
        .status {
            margin: 20px 0;
            padding: 10px;
            border-radius: 5px;
            background: rgba(255,255,255,0.1);
        }
        .loading { color: #ffd700; }
        .ready { color: #00ff41; }
        .error { color: #ff6b6b; }
    </style>
</head>
<body>
    <div class=\"container\">
        <h1>${title}</h1>
        <div id=\"status\" class=\"status loading\">Loading WebAssembly...</div>
        <canvas id=\"${canvas_id}\" width=\"800\" height=\"600\"></canvas>
        <div class=\"controls\">
            <button onclick=\"Module.requestFullscreen()\">Fullscreen</button>
            <button onclick=\"document.getElementById('output').innerHTML = ''\">Clear Console</button>
        </div>
        <div id=\"output\" class=\"output\"></div>
    </div>
    
    <script>
        var Module = {
            canvas: document.getElementById('${canvas_id}'),
            print: function(text) {
                var output = document.getElementById('output');
                output.innerHTML += text + '\\n';
                output.scrollTop = output.scrollHeight;
            },
            printErr: function(text) {
                var output = document.getElementById('output');
                output.innerHTML += '<span style=\"color: #ff6b6b;\">' + text + '</span>\\n';
                output.scrollTop = output.scrollHeight;
            },
            onRuntimeInitialized: function() {
                document.getElementById('status').innerHTML = 'WebAssembly Ready';
                document.getElementById('status').className = 'status ready';
            },
            onAbort: function(what) {
                document.getElementById('status').innerHTML = 'WebAssembly Error: ' + what;
                document.getElementById('status').className = 'status error';
            }
        };
    </script>
    {{{ SCRIPT }}}
</body>
</html>")
    
    set(${output_var} "${HTML_CONTENT}" PARENT_SCOPE)
endfunction()
