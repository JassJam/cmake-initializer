# Hello Testing Frameworks Sample
# Choose testing framework: doctest (default), gtest, catch2, or boost

set(TEST_FRAMEWORK "doctest" CACHE STRING "Testing framework")
set_property(CACHE TEST_FRAMEWORK PROPERTY STRINGS "doctest" "gtest" "catch2" "boost")

message(STATUS "Using testing framework: ${TEST_FRAMEWORK}")

# Register the test framework globally
register_test_framework(${TEST_FRAMEWORK})

# Create library to test
register_library(MathUtils STATIC INSTALL)

# Create main executable  
register_executable(HelloTestingFrameworks LIBRARIES MathUtils INSTALL)

# Add tests
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
