register_executable(HelloPackages
    SOURCES
        src/main.cpp
    HEADERS
        include/hello_world.hpp
    INCLUDE_DIRS
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    NAMESPACE    ${THIS_PROJECT_NAMESPACE}
    EXPORT_SET   "${THIS_PROJECT_NAMESPACE}Targets"
)
include(Dependencies.cmake)