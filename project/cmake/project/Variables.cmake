# Disable CXX extensions to not use compiler-specific features
set(CMAKE_CXX_EXTENSIONS OFF)

# Generate compile_commands.json for tools like clang-tidy or IDEs
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Set target scope types for CMake targets
set(CMAKE_TARGET_SCOPE_TYPES PRIVATE PUBLIC INTERFACE)
