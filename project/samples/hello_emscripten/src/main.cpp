#include <iostream>
#include <string>
#include <chrono>
#include <thread>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include <emscripten/html5.h>

// Function callable from JavaScript
extern "C" {
    void EMSCRIPTEN_KEEPALIVE say_hello(const char* name) {
        std::cout << "Hello " << name << " from C++!" << std::endl;
    }
    
    int EMSCRIPTEN_KEEPALIVE add_numbers(int a, int b) {
        return a + b;
    }
}

#endif

int main() {
    std::cout << "=== Hello Emscripten Example ===" << std::endl;
    
#ifdef __EMSCRIPTEN__
    std::cout << "Running in WebAssembly environment!" << std::endl;
    std::cout << "Emscripten version: " << __EMSCRIPTEN_major__ << "." 
              << __EMSCRIPTEN_minor__ << "." << __EMSCRIPTEN_tiny__ << std::endl;
    
    // Print some information about the environment
    std::cout << "This example demonstrates:" << std::endl;
    std::cout << "  - C++ compilation to WebAssembly" << std::endl;
    std::cout << "  - JavaScript callable functions" << std::endl;
    std::cout << "  - Console output" << std::endl;
    
    // Simple demo instead of main loop for Node.js compatibility
    for (int i = 0; i < 5; ++i) {
        std::cout << "WebAssembly iteration " << (i + 1) << "/5" << std::endl;
    }
    
    std::cout << "WebAssembly demo completed!" << std::endl;
    
#else
    // Native compilation - just run a simple demo
    std::cout << "Running in native environment!" << std::endl;
    std::cout << "This is the native version of the Emscripten example." << std::endl;
    
    for (int i = 0; i < 5; ++i) {
        std::cout << "Iteration " << (i + 1) << "/5" << std::endl;
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
    
    std::cout << "Native demo completed!" << std::endl;
#endif
    
    return 0;
}
