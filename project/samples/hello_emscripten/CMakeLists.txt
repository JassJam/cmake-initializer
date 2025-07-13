register_emscripten(HelloEmscripten
    SOURCES src/main.cpp
    HTML_TEMPLATE "${CMAKE_CURRENT_SOURCE_DIR}/custom_template.html"
    HTML_TITLE "Hello Emscripten - WebAssembly Demo"
    CANVAS_ID "hello-canvas"
    INITIAL_MEMORY 16MB
    STACK_SIZE 5MB
    EXPORTED_RUNTIME_METHODS ccall cwrap UTF8ToString lengthBytesUTF8 requestFullscreen
    PTHREAD
    INSTALL
)

# Example of minimal usage (just uncomment to try):
# register_emscripten(HelloEmscripten
#     SOURCES src/main.cpp
# )

# Example with advanced Emscripten settings:
# register_emscripten(HelloEmscripten
#     SOURCES src/main.cpp src/utils.cpp
#     WASM_NAME "hello_advanced"
#     HTML_TITLE "Advanced WebAssembly App"
#     MEMORY_SIZE "128MB"
#     EMSCRIPTEN_FLAGS 
#         "-s WASM=1"
#         "-s USE_SDL=2"
#         "--bind"
#     INSTALL_WASM
# )
