# Hello Testing Frameworks Sample

# Create library to test
register_library(MathUtils STATIC INSTALL)

# Add tests
if (BUILD_TESTING)
    add_subdirectory(tests)
endif ()
