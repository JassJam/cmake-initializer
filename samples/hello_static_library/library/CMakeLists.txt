register_library(HelloWorld_StaticLibrary_Library
    STATIC
    SOURCES
        src/hello_world.cpp
    HEADERS
        include/hello_world.hpp
    INCLUDE_DIRS
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    NAMESPACE    ${THIS_PROJECT_NAMESPACE}
    EXPORT_SET   "${THIS_PROJECT_NAMESPACE}Targets"
)