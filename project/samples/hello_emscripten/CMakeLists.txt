register_emscripten(HelloEmscripten
        SOURCES src/main.cpp
        HTML_TEMPLATE "${CMAKE_CURRENT_SOURCE_DIR}/custom_template.html"
        HTML_TITLE "Hello Emscripten - WebAssembly Demo"
        CANVAS_ID "hello-canvas"
        INITIAL_MEMORY 16MB
        STACK_SIZE 5MB
        EXPORTED_RUNTIME_METHODS ccall cwrap UTF8ToString lengthBytesUTF8
        PTHREAD
        INSTALL
)
