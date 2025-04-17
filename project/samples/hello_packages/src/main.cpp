#include <iostream>
#include <spdlog/spdlog.h>

int main()
{
    spdlog::log(spdlog::level::info, "Hello {}!", "world");
    return 0;
}