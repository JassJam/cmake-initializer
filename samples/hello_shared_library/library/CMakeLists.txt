register_library(HelloWorld_SharedLibrary_Library
    SHARED
    SOURCES
        src/hello_world.cpp
    HEADERS
        include/hello_world.hpp
    INCLUDE_DIRS
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    EXPORT_HEADER     export.hpp
    EXPORT_MACRO_NAME HELLOWORLD_EXPORT
    NAMESPACE    ${THIS_PROJECT_NAMESPACE}
    EXPORT_SET   "${THIS_PROJECT_NAMESPACE}Targets"
)