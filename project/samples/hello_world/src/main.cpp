#include "hello_world.hpp"

#include <iostream>

int main()
{
    std::cout << HelloWorld() << std::endl;
#ifdef USER_NAME
    std::cout << "User: " << USER_NAME << std::endl;
#endif
#ifdef DEBUG_MODE
    std::cout << "Debug: " << DEBUG_MODE << std::endl;
#endif
#ifdef MAX_ITERATIONS
    std::cout << "Max Iterations: " << MAX_ITERATIONS << std::endl;
#endif
    return 0;
}
