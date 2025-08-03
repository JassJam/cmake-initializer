# ==============================================================================
# Register Emscripten Module
# ==============================================================================
# Simplified one-liner interface for WebAssembly/Emscripten target registration.
# This module provides a streamlined API for creating WebAssembly applications.

include_guard(GLOBAL)
include(SetupCommonProjectOptions)
include(${CMAKE_SOURCE_DIR}/cmake/toolchains/emscripten/EmsdkManager.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/toolchains/emscripten/EmscriptenTemplate.cmake)

# Initialize Emscripten environment if needed
function(_ensure_emscripten_ready)
    if(NOT DEFINED EMSDK_INITIALIZED)
        verify_and_setup_emscripten_compilers()
        configure_emscripten_html_generation()
        set(EMSDK_INITIALIZED TRUE CACHE INTERNAL "EMSDK has been initialized")
    endif()
endfunction()

# One-liner function to register an Emscripten/WebAssembly target
# Usage:
# register_emscripten(MyWebApp
#     [SOURCES src1.cpp src2.cpp ...]        # Source files (required)
#     [HEADERS header1.hpp header2.hpp ...]  # Header files for IDE integration
#     [INCLUDES include/dir1 include/dir2]   # Include directories
#     [LIBRARIES lib1 lib2 ...]              # Link libraries
#     [DEPENDENCIES dep1 dep2 ...]           # Target dependencies
#     [ENVIRONMENT dev|prod|test|...]        # Environment for loading .env files
#     
#     # HTML/Web Configuration
#     [HTML_TEMPLATE path/to/template.html]  # Custom HTML shell template
#     [HTML_TITLE "App Title"]               # HTML page title
#     [CANVAS_ID "canvas"]                   # Canvas element ID
#     [OUTPUT_DIR output/path]               # Custom output directory
#     
#     # WebAssembly Settings
#     [EXPORTED_FUNCTIONS func1 func2 ...]   # C++ functions to export to JavaScript
#     [EXPORTED_RUNTIME_METHODS ccall cwrap] # Emscripten runtime methods to export
#     [PRELOAD_FILES file1 file2 ...]        # Files to preload into virtual filesystem
#     [EMBED_FILES file1 file2 ...]          # Files to embed into the binary
#     
#     # Memory Configuration
#     [INITIAL_MEMORY 16MB]                  # Initial memory pool (16MB, 64MB, etc.)
#     [MAXIMUM_MEMORY 128MB]                 # Maximum memory (if ALLOW_MEMORY_GROWTH)
#     [STACK_SIZE 5MB]                       # Stack size (1MB, 5MB, etc.)
#     
#     # Build Options
#     [WASM]                                 # Enable WebAssembly output (default: ON)
#     [STANDALONE_WASM]                      # Standalone WASM without JS glue code
#     [NODE_JS]                              # Target Node.js environment
#     [PTHREAD]                              # Enable pthreads support
#     [SIMD]                                 # Enable SIMD optimizations
#     [ASYNCIFY]                             # Enable async/await support
#     [ASSERTIONS]                           # Enable runtime assertions
#     [SAFE_HEAP]                            # Enable heap safety checks
#     [DEMANGLE_SUPPORT]                     # Enable C++ symbol demangling
#     [ALLOW_MEMORY_GROWTH]                  # Allow dynamic memory growth
#     [CLOSURE_COMPILER]                     # Use Closure Compiler for minification
#     
#     # Installation
#     [INSTALL]                              # Install target to CMAKE_INSTALL_PREFIX
#     [INSTALL_DESTINATION path]             # Custom install destination
# )
function(register_emscripten TARGET_NAME)
    # Early return if not building with Emscripten
    include(GetCurrentCompiler)
    get_current_compiler(CURRENT_COMPILER)
    if(NOT CURRENT_COMPILER STREQUAL "EMSCRIPTEN")
        message(STATUS "Skipping Emscripten target '${TARGET_NAME}' - not building with Emscripten compiler")
        return()
    endif()

    set(options WASM TANDALONE_WASM NODE_JS PTHREAD SIMD ASYNCIFY ASSERTIONS
        SAFE_HEAP DEMANGLE_SUPPORT ALLOW_MEMORY_GROWTH CLOSURE_COMPILER INSTALL)
    set(oneValueArgs HTML_TEMPLATE HTML_TITLE CANVAS_ID OUTPUT_DIR INITIAL_MEMORY
        MAXIMUM_MEMORY STACK_SIZE INSTALL_DESTINATION ENVIRONMENT)
    set(multiValueArgs SOURCES HEADERS INCLUDES LIBRARIES DEPENDENCIES EXPORTED_FUNCTIONS
        EXPORTED_RUNTIME_METHODS PRELOAD_FILES EMBED_FILES)
    
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Validate arguments
    if(NOT ARG_SOURCES)
        message(FATAL_ERROR "register_emscripten: SOURCES argument is required")
    endif()

    _ensure_emscripten_ready()
    
    message(STATUS "Registering Emscripten target: ${TARGET_NAME}")
    
    # Create the executable target
    add_executable(${TARGET_NAME} ${ARG_SOURCES})
    
    # Load .env and .env.<ENVIRONMENT> if ENVIRONMENT is set
    set(_env_file "${CMAKE_CURRENT_LIST_DIR}/.env")
    include(LoadEnvVariable)
    target_load_env_files(${TARGET_NAME} "${_env_file}" "${_env_file}.${ARG_ENVIRONMENT}")

    # Add headers for IDE integration
    if(ARG_HEADERS)
        target_sources(${TARGET_NAME} PRIVATE ${ARG_HEADERS})
    endif()
    
    # Configure include directories
    if(ARG_INCLUDES)
        target_include_directories(${TARGET_NAME} PRIVATE ${ARG_INCLUDES})
    endif()
    
    # Link libraries
    if(ARG_LIBRARIES)
        target_link_libraries(${TARGET_NAME} PRIVATE ${ARG_LIBRARIES})
    endif()
    
    # Add dependencies
    if(ARG_DEPENDENCIES)
        add_dependencies(${TARGET_NAME} ${ARG_DEPENDENCIES})
    endif()
    
    # Configure HTML output
    _configure_emscripten_html_output(${TARGET_NAME}
        HTML_TEMPLATE "${ARG_HTML_TEMPLATE}"
        HTML_TITLE "${ARG_HTML_TITLE}"
        CANVAS_ID "${ARG_CANVAS_ID}"
        OUTPUT_DIR "${ARG_OUTPUT_DIR}"
    )
    
    # Configure WebAssembly settings
    # Build argument list for _configure_emscripten_wasm_settings
    set(WASM_ARGS
        EXPORTED_FUNCTIONS "${ARG_EXPORTED_FUNCTIONS}"
        EXPORTED_RUNTIME_METHODS "${ARG_EXPORTED_RUNTIME_METHODS}"
        PRELOAD_FILES "${ARG_PRELOAD_FILES}"
        EMBED_FILES "${ARG_EMBED_FILES}"
        INITIAL_MEMORY "${ARG_INITIAL_MEMORY}"
        MAXIMUM_MEMORY "${ARG_MAXIMUM_MEMORY}"
        STACK_SIZE "${ARG_STACK_SIZE}"
    )
    
    # Add boolean flags only when they are TRUE
    if(ARG_WASM)
        list(APPEND WASM_ARGS WASM)
    endif()
    if(ARG_STANDALONE_WASM)
        list(APPEND WASM_ARGS STANDALONE_WASM)
    endif()
    if(ARG_NODE_JS)
        list(APPEND WASM_ARGS NODE_JS)
    endif()
    if(ARG_PTHREAD)
        list(APPEND WASM_ARGS PTHREAD)
    endif()
    if(ARG_SIMD)
        list(APPEND WASM_ARGS SIMD)
    endif()
    if(ARG_ASYNCIFY)
        list(APPEND WASM_ARGS ASYNCIFY)
    endif()
    if(ARG_ASSERTIONS)
        list(APPEND WASM_ARGS ASSERTIONS)
    endif()
    if(ARG_SAFE_HEAP)
        list(APPEND WASM_ARGS SAFE_HEAP)
    endif()
    if(ARG_DEMANGLE_SUPPORT)
        list(APPEND WASM_ARGS DEMANGLE_SUPPORT)
    endif()
    if(ARG_ALLOW_MEMORY_GROWTH)
        list(APPEND WASM_ARGS ALLOW_MEMORY_GROWTH)
    endif()
    if(ARG_CLOSURE_COMPILER)
        list(APPEND WASM_ARGS CLOSURE_COMPILER)
    endif()
    
    _configure_emscripten_wasm_settings(${TARGET_NAME} ${WASM_ARGS})
    
    # Link config library
    target_link_libraries(${TARGET_NAME} PRIVATE ${THIS_PROJECT_NAMESPACE}::config)
    
    # Apply common project options (warnings, sanitizers, static analysis, etc.)
    setup_common_project_options(${TARGET_NAME})
    
    # Configure installation
    if(ARG_INSTALL)
        _configure_emscripten_installation(${TARGET_NAME}
            INSTALL_DESTINATION "${ARG_INSTALL_DESTINATION}"
        )
    endif()
    
    message(STATUS "Emscripten target '${TARGET_NAME}' configured successfully")
endfunction()

# Internal function to configure HTML output
function(_configure_emscripten_html_output target)
    cmake_parse_arguments(ARG "" "HTML_TEMPLATE;HTML_TITLE;CANVAS_ID;OUTPUT_DIR" "" ${ARGN})
    
    # Set default values
    if(NOT ARG_HTML_TITLE)
        set(ARG_HTML_TITLE "${TARGET_NAME} - WebAssembly Application")
    endif()
    
    if(NOT ARG_CANVAS_ID)
        set(ARG_CANVAS_ID "canvas")
    endif()
    
    # Create HTML template if not provided
    if(NOT ARG_HTML_TEMPLATE)
        set(TEMPLATE_DIR "${CMAKE_CURRENT_BINARY_DIR}/emscripten_templates")
        file(MAKE_DIRECTORY "${TEMPLATE_DIR}")
        set(ARG_HTML_TEMPLATE "${TEMPLATE_DIR}/${TARGET_NAME}_shell.html")
        
        _create_emscripten_html_template("${ARG_HTML_TEMPLATE}"
            TITLE "${ARG_HTML_TITLE}"
            CANVAS_ID "${ARG_CANVAS_ID}"
        )
    else()
        # Process custom template for variable substitution
        set(TEMPLATE_DIR "${CMAKE_CURRENT_BINARY_DIR}/emscripten_templates")
        file(MAKE_DIRECTORY "${TEMPLATE_DIR}")
        set(PROCESSED_TEMPLATE "${TEMPLATE_DIR}/${TARGET_NAME}_shell.html")
        
        _create_emscripten_html_template("${PROCESSED_TEMPLATE}"
            TITLE "${ARG_HTML_TITLE}"
            CANVAS_ID "${ARG_CANVAS_ID}"
            TEMPLATE_FILE "${ARG_HTML_TEMPLATE}"
        )
        
        # Update ARG_HTML_TEMPLATE to point to the processed template
        set(ARG_HTML_TEMPLATE "${PROCESSED_TEMPLATE}")
    endif()
    
    # Configure target to use HTML output
    set_target_properties(${TARGET_NAME} PROPERTIES
        OUTPUT_NAME "${TARGET_NAME}.html"
        SUFFIX ""
    )
    
    # Add shell file option
    target_link_options(${TARGET_NAME} PRIVATE "SHELL:--shell-file ${ARG_HTML_TEMPLATE}")
    
    message(STATUS "  - HTML output: ${TARGET_NAME}.html")
    message(STATUS "  - HTML template: ${ARG_HTML_TEMPLATE}")
endfunction()

# Internal function to configure WebAssembly settings
function(_configure_emscripten_wasm_settings target)
    cmake_parse_arguments(ARG
        "WASM;STANDALONE_WASM;NODE_JS;PTHREAD;SIMD;ASYNCIFY;ASSERTIONS;SAFE_HEAP;DEMANGLE_SUPPORT;ALLOW_MEMORY_GROWTH;CLOSURE_COMPILER"
        "INITIAL_MEMORY;MAXIMUM_MEMORY;STACK_SIZE"
        "EXPORTED_FUNCTIONS;EXPORTED_RUNTIME_METHODS;PRELOAD_FILES;EMBED_FILES"
        ${ARGN}
    )
    
    # WebAssembly output (default enabled)
    if(NOT DEFINED ARG_WASM OR ARG_WASM)
        target_link_options(${TARGET_NAME} PRIVATE "SHELL:-s WASM=1")
        message(STATUS "  - WebAssembly output: enabled")
    endif()
    
    # Standalone WebAssembly
    if(ARG_STANDALONE_WASM)
        target_link_options(${TARGET_NAME} PRIVATE "SHELL:-s STANDALONE_WASM=1")
        message(STATUS "  - Standalone WebAssembly: enabled")
    endif()
    
    # Memory configuration
    _configure_emscripten_memory(${TARGET_NAME}
        INITIAL_MEMORY "${ARG_INITIAL_MEMORY}"
        MAXIMUM_MEMORY "${ARG_MAXIMUM_MEMORY}"
        STACK_SIZE "${ARG_STACK_SIZE}"
        ALLOW_MEMORY_GROWTH ${ARG_ALLOW_MEMORY_GROWTH}
    )
    
    # Function exports
    if(ARG_EXPORTED_FUNCTIONS)
        string(JOIN "," EXPORTED_FUNCS ${ARG_EXPORTED_FUNCTIONS})
        target_link_options(${TARGET_NAME} PRIVATE "SHELL:-s EXPORTED_FUNCTIONS=[${EXPORTED_FUNCS}]")
        message(STATUS "  - Exported functions: ${EXPORTED_FUNCS}")
    endif()
    
    # Runtime method exports
    if(ARG_EXPORTED_RUNTIME_METHODS)
        string(JOIN "," EXPORTED_METHODS ${ARG_EXPORTED_RUNTIME_METHODS})
        target_link_options(${TARGET_NAME} PRIVATE "SHELL:-s EXPORTED_RUNTIME_METHODS=[${EXPORTED_METHODS}]")
        message(STATUS "  - Exported runtime methods: ${EXPORTED_METHODS}")
    endif()
    
    # File system configuration
    if(ARG_PRELOAD_FILES)
        foreach(file ${ARG_PRELOAD_FILES})
            target_link_options(${TARGET_NAME} PRIVATE "SHELL:--preload-file ${file}")
        endforeach()
        message(STATUS "  - Preloaded files: ${ARG_PRELOAD_FILES}")
    endif()
    
    if(ARG_EMBED_FILES)
        foreach(file ${ARG_EMBED_FILES})
            target_link_options(${TARGET_NAME} PRIVATE "SHELL:--embed-file ${file}")
        endforeach()
        message(STATUS "  - Embedded files: ${ARG_EMBED_FILES}")
    endif()
    
    # Advanced options
    if(ARG_PTHREAD)
        target_link_options(${TARGET_NAME} PRIVATE "SHELL:-s USE_PTHREADS=1")
        target_compile_options(${TARGET_NAME} PRIVATE "SHELL:-s USE_PTHREADS=1")
        message(STATUS "  - Pthreads support: enabled")
    endif()
    
    # Environment configuration (must come after pthread to check for worker requirement)
    if(ARG_NODE_JS)
        target_link_options(${TARGET_NAME} PRIVATE "SHELL:-s ENVIRONMENT=node")
        message(STATUS "  - Target environment: Node.js")
    else()
        # For web environment, include worker support if pthreads are enabled
        if(ARG_PTHREAD)
            target_link_options(${TARGET_NAME} PRIVATE "SHELL:-s ENVIRONMENT=web,worker")
            message(STATUS "  - Target environment: Web browser with worker support")
        else()
            target_link_options(${TARGET_NAME} PRIVATE "SHELL:-s ENVIRONMENT=web")
            message(STATUS "  - Target environment: Web browser")
        endif()
    endif()
    
    if(ARG_SIMD)
        # SIMD is now controlled by compiler flags only, not linker settings
        target_compile_options(${TARGET_NAME} PRIVATE "-msimd128")
        message(STATUS "  - SIMD optimizations: enabled")
    endif()
    
    if(ARG_ASYNCIFY)
        target_link_options(${TARGET_NAME} PRIVATE "SHELL:-s ASYNCIFY=1")
        message(STATUS "  - Asyncify (async/await): enabled")
    endif()
    
    if(ARG_ASSERTIONS)
        target_link_options(${TARGET_NAME} PRIVATE "SHELL:-s ASSERTIONS=1")
        message(STATUS "  - Runtime assertions: enabled")
    endif()
    
    if(ARG_SAFE_HEAP)
        target_link_options(${TARGET_NAME} PRIVATE "SHELL:-s SAFE_HEAP=1")
        message(STATUS "  - Safe heap checks: enabled")
    endif()
    
    if(ARG_DEMANGLE_SUPPORT)
        # DEMANGLE_SUPPORT is no longer supported in newer Emscripten versions
        # C++ symbol demangling is enabled by default
        message(STATUS "  - C++ symbol demangling: enabled")
    endif()
    
    if(ARG_CLOSURE_COMPILER)
        target_link_options(${TARGET_NAME} PRIVATE "SHELL:--closure 1")
        message(STATUS "  - Closure Compiler optimization: enabled")
    endif()
endfunction()

# Internal function to configure memory settings
function(_configure_emscripten_memory target)
    cmake_parse_arguments(ARG "ALLOW_MEMORY_GROWTH" "INITIAL_MEMORY;MAXIMUM_MEMORY;STACK_SIZE" "" ${ARGN})
    
    # Parse memory sizes (support units like 16MB, 64MB, etc.)
    if(ARG_INITIAL_MEMORY)
        _parse_memory_size("${ARG_INITIAL_MEMORY}" INITIAL_BYTES)
        target_link_options(${TARGET_NAME} PRIVATE "SHELL:-s INITIAL_MEMORY=${INITIAL_BYTES}")
        message(STATUS "  - Initial memory: ${ARG_INITIAL_MEMORY} (${INITIAL_BYTES} bytes)")
    endif()
    
    if(ARG_MAXIMUM_MEMORY)
        _parse_memory_size("${ARG_MAXIMUM_MEMORY}" MAXIMUM_BYTES)
        target_link_options(${TARGET_NAME} PRIVATE "SHELL:-s MAXIMUM_MEMORY=${MAXIMUM_BYTES}")
        message(STATUS "  - Maximum memory: ${ARG_MAXIMUM_MEMORY} (${MAXIMUM_BYTES} bytes)")
    endif()
    
    if(ARG_STACK_SIZE)
        _parse_memory_size("${ARG_STACK_SIZE}" STACK_BYTES)
        target_link_options(${TARGET_NAME} PRIVATE "SHELL:-s STACK_SIZE=${STACK_BYTES}")
        message(STATUS "  - Stack size: ${ARG_STACK_SIZE} (${STACK_BYTES} bytes)")
    endif()
    
    if(ARG_ALLOW_MEMORY_GROWTH)
        target_link_options(${TARGET_NAME} PRIVATE "SHELL:-s ALLOW_MEMORY_GROWTH=1")
        message(STATUS "  - Memory growth: enabled")
    endif()
endfunction()

# Internal function to parse memory sizes with units
function(_parse_memory_size size_string output_var)
    string(TOUPPER "${size_string}" size_upper)
    
    if(size_upper MATCHES "^([0-9]+)(KB|MB|GB)$")
        set(number ${CMAKE_MATCH_1})
        set(unit ${CMAKE_MATCH_2})
        
        if(unit STREQUAL "KB")
            math(EXPR bytes "${number} * 1024")
        elseif(unit STREQUAL "MB")
            math(EXPR bytes "${number} * 1024 * 1024")
        elseif(unit STREQUAL "GB")
            math(EXPR bytes "${number} * 1024 * 1024 * 1024")
        endif()
        
        set(${output_var} ${bytes} PARENT_SCOPE)
    elseif(size_upper MATCHES "^[0-9]+$")
        # Already in bytes
        set(${output_var} ${size_string} PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Invalid memory size format: ${size_string}. Use formats like '16MB', '64MB', '1GB', or raw bytes.")
    endif()
endfunction()

# Internal function to configure installation
function(_configure_emscripten_installation target)
    cmake_parse_arguments(ARG "" "INSTALL_DESTINATION" "" ${ARGN})
    
    if(NOT ARG_INSTALL_DESTINATION)
        set(ARG_INSTALL_DESTINATION "bin")
    endif()
    
    # Install the HTML file and associated assets
    install(FILES 
        "$<TARGET_FILE_DIR:${TARGET_NAME}>/${TARGET_NAME}.html"
        "$<TARGET_FILE_DIR:${TARGET_NAME}>/${TARGET_NAME}.js"
        "$<TARGET_FILE_DIR:${TARGET_NAME}>/${TARGET_NAME}.wasm"
        DESTINATION "${ARG_INSTALL_DESTINATION}"
        OPTIONAL
    )
    
    message(STATUS "  - Installation: ${ARG_INSTALL_DESTINATION}")
endfunction()

# Internal function to create HTML template from file or default
function(_create_emscripten_html_template output_file)
    cmake_parse_arguments(ARG "" "TITLE;CANVAS_ID;TEMPLATE_FILE" "" ${ARGN})
    
    # Set defaults
    if(NOT ARG_TITLE)
        set(ARG_TITLE "WebAssembly Application")
    endif()
    
    if(NOT ARG_CANVAS_ID)
        set(ARG_CANVAS_ID "canvas")
    endif()
    
    # Check if custom template file is provided
    if(ARG_TEMPLATE_FILE AND EXISTS "${ARG_TEMPLATE_FILE}")
        # Read template from file and substitute variables
        file(READ "${ARG_TEMPLATE_FILE}" TEMPLATE_CONTENT)
        string(REPLACE "{{TITLE}}" "${ARG_TITLE}" TEMPLATE_CONTENT "${TEMPLATE_CONTENT}")
        string(REPLACE "{{CANVAS_ID}}" "${ARG_CANVAS_ID}" TEMPLATE_CONTENT "${TEMPLATE_CONTENT}")
        file(WRITE "${output_file}" "${TEMPLATE_CONTENT}")
        message(STATUS "Created HTML template from: ${ARG_TEMPLATE_FILE}")
    else()
        # Use default template
        _create_default_html_template("${output_file}" "${ARG_TITLE}" "${ARG_CANVAS_ID}")
        message(STATUS "Created default HTML template")
    endif()
endfunction()

# Internal function to create default HTML template
function(_create_default_html_template output_file title canvas_id)
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
        .loading {
            color: #ffd700;
        }
        .ready {
            color: #00ff41;
        }
        .error {
            color: #ff6b6b;
        }
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
    
    file(WRITE "${output_file}" "${HTML_CONTENT}")
endfunction()

# Configure HTML generation for Emscripten builds
function(configure_emscripten_html_generation)
    if(NOT EMSCRIPTEN_GENERATE_HTML)
        return()
    endif()
    
    # Set default HTML shell file template
    set(EMSCRIPTEN_HTML_SHELL_TEMPLATE "${CMAKE_SOURCE_DIR}/.emsdk/emscripten_shell.html")
    
    # Create HTML template if it doesn't exist
    if(NOT EXISTS "${EMSCRIPTEN_HTML_SHELL_TEMPLATE}")
        create_emscripten_html_template("${EMSCRIPTEN_HTML_SHELL_TEMPLATE}" 
            TITLE "cmake-initializer WebAssembly App"
            CANVAS_ID "canvas"
        )
    endif()
    
    # Set global linker flags for HTML generation
    add_link_options("SHELL:--shell-file ${EMSCRIPTEN_HTML_SHELL_TEMPLATE}")
    
    message(STATUS "Emscripten HTML generation enabled")
    message(STATUS "  - HTML shell template: ${EMSCRIPTEN_HTML_SHELL_TEMPLATE}")
    message(STATUS "  - Output will be .html files with embedded WebAssembly")
endfunction()
