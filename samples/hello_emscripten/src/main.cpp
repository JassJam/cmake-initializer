#include <iostream>
#include <string>
#include <chrono>
#include <thread>

#ifdef __EMSCRIPTEN__
    #include <emscripten.h>
    #include <emscripten/html5.h>

// Function callable from JavaScript
extern "C"
{
void EMSCRIPTEN_KEEPALIVE say_hello(const char* name)
{
    std::cout << "Hello " << name << " from C++!" << std::endl;
}

int EMSCRIPTEN_KEEPALIVE add_numbers(int a, int b)
{
    return a + b;
}
}

#if defined(__EMSCRIPTEN_MAJOR__)
#define VERSION_EMSCRIPTEN_MAJOR __EMSCRIPTEN_MAJOR__
#elif defined(__EMSCRIPTEN_major__)
#define VERSION_EMSCRIPTEN_MAJOR __EMSCRIPTEN_major__
#else
#define VERSION_EMSCRIPTEN_MAJOR "x"
#endif

#if defined(__EMSCRIPTEN_MINOR__)
#define VERSION_EMSCRIPTEN_MINOR __EMSCRIPTEN_MINOR__
#elif defined(__EMSCRIPTEN_minor__)
#define VERSION_EMSCRIPTEN_MINOR __EMSCRIPTEN_minor__
#else
#define VERSION_EMSCRIPTEN_MINOR "x"
#endif

#if defined(__EMSCRIPTEN_TINY__)
#define VERSION_EMSCRIPTEN_TINY __EMSCRIPTEN_TINY__
#elif defined(__EMSCRIPTEN_tiny__)
#define VERSION_EMSCRIPTEN_TINY __EMSCRIPTEN_tiny__
#else
#define VERSION_EMSCRIPTEN_TINY "x"
#endif

#endif

int main()
{
    std::cout << "=== Hello Emscripten Example ===" << std::endl;

#ifdef __EMSCRIPTEN__

    std::cout << "Running in WebAssembly environment!" << std::endl;
    std::cout << "Emscripten version: " << VERSION_EMSCRIPTEN_MAJOR << "." << VERSION_EMSCRIPTEN_MINOR
              << "." << VERSION_EMSCRIPTEN_TINY << std::endl;

    // Print some information about the environment
    std::cout << "This example demonstrates:" << std::endl;
    std::cout << "  - C++ compilation to WebAssembly" << std::endl;
    std::cout << "  - JavaScript callable functions" << std::endl;
    std::cout << "  - Console output" << std::endl;

    // Simple demo instead of main loop for Node.js compatibility
    for (int i = 0; i < 5; ++i)
    {
        std::cout << "WebAssembly iteration " << (i + 1) << "/5" << std::endl;
    }

    std::cout << "WebAssembly demo completed!" << std::endl;

#else
    // Native compilation - just run a simple demo
    std::cout << "Running in native environment!" << std::endl;
    std::cout << "This is the native version of the Emscripten example." << std::endl;

    for (int i = 0; i < 5; ++i)
    {
        std::cout << "Iteration " << (i + 1) << "/5" << std::endl;
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }

    std::cout << "Native demo completed!" << std::endl;
#endif

    return 0;
}
