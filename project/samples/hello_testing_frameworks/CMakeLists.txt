# Hello Testing Frameworks Sample

# Create library to test
register_library(MathUtils STATIC INSTALL)

# Create main executable  
register_executable(HelloTestingFrameworks LIBRARIES MathUtils INSTALL)

# Add tests
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
