# Hello Testing Frameworks Sample

# Create library to test
register_library(MathUtils
    STATIC
    SOURCES
        src/math_utils.cpp
    HEADERS
        include/math_utils.hpp
    INCLUDE_DIRS
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    NAMESPACE    ${THIS_PROJECT_NAMESPACE}
    EXPORT_SET   "${THIS_PROJECT_NAMESPACE}Targets"
)

# Add tests
if (BUILD_TESTING)
    add_subdirectory(tests)
endif ()
