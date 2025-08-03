# ==============================================================================
# Testing Framework Registration System
# ==============================================================================

include_guard(GLOBAL)
include(SetupCommonProjectOptions)

# Configuration Variables:
# - EMSCRIPTEN_NODE_EXECUTABLE: Path to Node.js executable for running Emscripten tests
#   Defaults to auto-detection from EMSDK or system PATH
# - EMSCRIPTEN_TEST_OPTIONS: Additional options for Emscripten test execution
#   Example: "--experimental-wasm-bigint --max-old-space-size=4096"

# Global variables to store test framework configuration
set_property(GLOBAL PROPERTY TEST_FRAMEWORK_REGISTERED FALSE)
set_property(GLOBAL PROPERTY TEST_FRAMEWORK_NAME "")
set_property(GLOBAL PROPERTY TEST_FRAMEWORK_LIBRARIES "")

# Register a test framework globally (call once in main CMakeLists.txt)
# Usage:
# register_test_framework("doctest") (or "catch2", "gtest", "boost")
function(register_test_framework FRAMEWORK_NAME)
    # Skip if testing is disabled
    if(NOT BUILD_TESTING)
        message(STATUS "Testing disabled, skipping test framework registration")
        return()
    endif()
    
    get_property(already_registered GLOBAL PROPERTY TEST_FRAMEWORK_REGISTERED)
    if(already_registered)
        message(WARNING "Test framework already registered. Skipping duplicate registration.")
        return()
    endif()

    message(STATUS "Registering test framework: ${FRAMEWORK_NAME}")
    
    # Set up framework-specific configuration
    if(FRAMEWORK_NAME STREQUAL "doctest")
        CPMAddPackage(
            NAME doctest
            GITHUB_REPOSITORY doctest/doctest
            GIT_TAG v2.4.11
            SYSTEM ON
        )
        set(FRAMEWORK_LIBS doctest::doctest)
        set(FRAMEWORK_DEFS "DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN")
        
    elseif(FRAMEWORK_NAME STREQUAL "catch2")
        CPMAddPackage(
            NAME Catch2
            GITHUB_REPOSITORY catchorg/Catch2
            GIT_TAG v3.5.2
            SYSTEM ON
        )
        set(FRAMEWORK_LIBS Catch2::Catch2WithMain )
        set(FRAMEWORK_DEFS "")
        
    elseif(FRAMEWORK_NAME STREQUAL "gtest")
        CPMAddPackage(
            NAME googletest
            GITHUB_REPOSITORY google/googletest
            GIT_TAG v1.14.0
            SYSTEM ON
        )
        set(FRAMEWORK_LIBS gtest_main)
        set(FRAMEWORK_DEFS "")
        
    elseif(FRAMEWORK_NAME STREQUAL "boost")
        CPMAddPackage(
            NAME boost
            GITHUB_REPOSITORY boostorg/boost
            GIT_TAG boost-1.84.0
            OPTIONS
                "BOOST_ENABLE_CMAKE ON"
                "BOOST_INCLUDE_LIBRARIES test"
            SYSTEM ON
        )
        set(FRAMEWORK_LIBS Boost::unit_test_framework)
        set(FRAMEWORK_DEFS "BOOST_TEST_MODULE=Tests")
        
    else()
        message(FATAL_ERROR "Unknown test framework: ${FRAMEWORK_NAME}. Supported: doctest, catch2, gtest, boost")
    endif()

    # Store configuration globally
    set_property(GLOBAL PROPERTY TEST_FRAMEWORK_REGISTERED TRUE)
    set_property(GLOBAL PROPERTY TEST_FRAMEWORK_NAME "${FRAMEWORK_NAME}")
    set_property(GLOBAL PROPERTY TEST_FRAMEWORK_LIBRARIES "${FRAMEWORK_LIBS}")
    set_property(GLOBAL PROPERTY TEST_FRAMEWORK_DEFINITIONS "${FRAMEWORK_DEFS}")
    
    message(STATUS "Test framework '${FRAMEWORK_NAME}' registered successfully")
endfunction()

# Comprehensive test creation function - uses the registered test framework
# Usage:
# register_test(MyTest
#     SOURCE_DIR "tests"
#     SOURCES PRIVATE "test_main.cpp" "test_utils.cpp" PUBLIC "api_test.cpp"
#     INCLUDES PRIVATE "private/include" PUBLIC "public/include" INTERFACE "interface/include"
#     LIBRARIES PRIVATE "private_lib" PUBLIC "public_lib" INTERFACE "interface_lib"
#     DEPENDENCIES PRIVATE "dep1" PUBLIC "dep2" INTERFACE "dep3"
#     COMPILE_DEFINITIONS PRIVATE "TEST_PRIVATE" PUBLIC "TEST_PUBLIC" INTERFACE "TEST_INTERFACE"
#     COMPILE_OPTIONS PRIVATE "-Wall" PUBLIC "-O2" INTERFACE "-fPIC"
#     COMPILE_FEATURES PRIVATE "cxx_std_17" PUBLIC "cxx_std_20" INTERFACE "cxx_std_23"
#     LINK_OPTIONS PRIVATE "-static" PUBLIC "-shared" INTERFACE "-fPIC"
#     PROPERTIES "PROPERTY1" "value1" "PROPERTY2" "value2"
#     ENVIRONMENT [dev|prod|test|...]
#     INSTALL
# )
function(register_test TARGET_NAME)
    # Skip if testing is disabled
    if(NOT BUILD_TESTING)
        message(STATUS "Testing disabled, skipping test registration for ${TARGET_NAME}")
        return()
    endif()
    
    set(options INSTALL DEPENDENCIES)
    set(oneValueArgs SOURCE_DIR ENVIRONMENT)
    set(multiValueArgs SOURCES INCLUDES LIBRARIES DEPENDENCY_LIST
        COMPILE_DEFINITIONS COMPILE_OPTIONS COMPILE_FEATURES LINK_OPTIONS PROPERTIES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Check if test framework is registered
    get_property(framework_registered GLOBAL PROPERTY TEST_FRAMEWORK_REGISTERED)
    if(NOT framework_registered)
        message(FATAL_ERROR "No test framework registered. Call register_test_framework() first.")
    endif()

    # Get framework configuration
    get_property(framework_name GLOBAL PROPERTY TEST_FRAMEWORK_NAME)
    get_property(framework_libs GLOBAL PROPERTY TEST_FRAMEWORK_LIBRARIES)
    get_property(framework_defs GLOBAL PROPERTY TEST_FRAMEWORK_DEFINITIONS)

    # Set defaults
    if(NOT ARG_SOURCE_DIR)
        set(ARG_SOURCE_DIR ".")  # Default to current directory
    endif()

    # Create test executable
    add_executable(${TARGET_NAME})

    # Load .env and .env.<ENVIRONMENT> if ENVIRONMENT is set
    set(_env_file "${CMAKE_CURRENT_LIST_DIR}/.env")
    include(LoadEnvVariable)
    target_load_env_files(${TARGET_NAME} "${_env_file}" "${_env_file}.${ARG_ENVIRONMENT}")

    # Add test sources with visibility
    if(ARG_SOURCES)
        set(current_visibility "PRIVATE")  # Default visibility for sources
        foreach(item ${ARG_SOURCES})
            if(item STREQUAL "PRIVATE" OR item STREQUAL "PUBLIC" OR item STREQUAL "INTERFACE")
                set(current_visibility ${item})
            else()
                target_sources(${TARGET_NAME} ${current_visibility} ${item})
            endif()
        endforeach()
    else()
        # Try framework-specific test file first
        set(FRAMEWORK_TEST_FILE "test_${framework_name}.cpp")
        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${FRAMEWORK_TEST_FILE}")
            target_sources(${TARGET_NAME} PRIVATE ${FRAMEWORK_TEST_FILE})
        else()
            # Auto-discover test sources
            file(GLOB_RECURSE TEST_SOURCES 
                "${ARG_SOURCE_DIR}/*.cpp" 
                "${ARG_SOURCE_DIR}/*.c"
                "${ARG_SOURCE_DIR}/test_*.cpp"
                "${ARG_SOURCE_DIR}/*_test.cpp"
            )
            if(TEST_SOURCES)
                target_sources(${TARGET_NAME} PRIVATE ${TEST_SOURCES})
            else()
                message(FATAL_ERROR "No test sources found. Expected ${FRAMEWORK_TEST_FILE} or other test files in ${ARG_SOURCE_DIR}/")
            endif()
        endif()
    endif()

    # Add includes with visibility
    if(ARG_INCLUDES)
        set(current_visibility "PRIVATE")  # Default visibility for tests
        foreach(item ${ARG_INCLUDES})
            if(item STREQUAL "PRIVATE" OR item STREQUAL "PUBLIC" OR item STREQUAL "INTERFACE")
                set(current_visibility ${item})
            else()
                target_include_directories(${TARGET_NAME} ${current_visibility} ${item})
            endif()
        endforeach()
    endif()

    # Add libraries with visibility (always include framework and config)
    target_link_libraries(${TARGET_NAME} PRIVATE 
        ${framework_libs} ${THIS_PROJECT_NAMESPACE}::config)
    
    if(ARG_LIBRARIES)
        set(current_visibility "PRIVATE")  # Default visibility for tests
        foreach(item ${ARG_LIBRARIES})
            if(item STREQUAL "PRIVATE" OR item STREQUAL "PUBLIC" OR item STREQUAL "INTERFACE")
                set(current_visibility ${item})
            else()
                target_link_libraries(${TARGET_NAME} ${current_visibility} ${item})
            endif()
        endforeach()
    endif()

    # Add compile definitions with visibility
    if(ARG_COMPILE_DEFINITIONS)
        set(current_visibility "PRIVATE")  # Default visibility
        foreach(item ${ARG_COMPILE_DEFINITIONS})
            if(item STREQUAL "PRIVATE" OR item STREQUAL "PUBLIC" OR item STREQUAL "INTERFACE")
                set(current_visibility ${item})
            else()
                target_compile_definitions(${TARGET_NAME} ${current_visibility} ${item})
            endif()
        endforeach()
    endif()

    # Add compile options with visibility
    if(ARG_COMPILE_OPTIONS)
        set(current_visibility "PRIVATE")  # Default visibility
        foreach(item ${ARG_COMPILE_OPTIONS})
            if(item STREQUAL "PRIVATE" OR item STREQUAL "PUBLIC" OR item STREQUAL "INTERFACE")
                set(current_visibility ${item})
            else()
                target_compile_options(${TARGET_NAME} ${current_visibility} ${item})
            endif()
        endforeach()
    endif()

    # Add compile features with visibility
    if(ARG_COMPILE_FEATURES)
        set(current_visibility "PRIVATE")  # Default visibility
        foreach(item ${ARG_COMPILE_FEATURES})
            if(item STREQUAL "PRIVATE" OR item STREQUAL "PUBLIC" OR item STREQUAL "INTERFACE")
                set(current_visibility ${item})
            else()
                target_compile_features(${TARGET_NAME} ${current_visibility} ${item})
            endif()
        endforeach()
    endif()

    # Add link options with visibility
    if(ARG_LINK_OPTIONS)
        set(current_visibility "PRIVATE")  # Default visibility
        foreach(item ${ARG_LINK_OPTIONS})
            if(item STREQUAL "PRIVATE" OR item STREQUAL "PUBLIC" OR item STREQUAL "INTERFACE")
                set(current_visibility ${item})
            else()
                target_link_options(${TARGET_NAME} ${current_visibility} ${item})
            endif()
        endforeach()
    endif()

    # Set target properties
    if(ARG_PROPERTIES)
        set_target_properties(${TARGET_NAME} PROPERTIES ${ARG_PROPERTIES})
    endif()

    # Handle dependencies
    if(ARG_DEPENDENCIES)
        # Check if Dependencies.cmake exists and include it
        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Dependencies.cmake")
            include(Dependencies.cmake)
        endif()
        
        # Check if target_load_dependencies function exists and call it
        if(COMMAND target_load_dependencies)
            target_load_dependencies(${TARGET_NAME})
        else()
            message(WARNING "DEPENDENCIES option specified but target_load_dependencies function not found. Make sure Dependencies.cmake is present and defines this function.")
        endif()
    endif()

    # Add framework-specific compile definitions
    if(framework_defs)
        target_compile_definitions(${TARGET_NAME} PRIVATE ${framework_defs})
    endif()

    # Include current project's include directory if it exists
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include")
        target_include_directories(${TARGET_NAME} PRIVATE
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        )
    endif()

    # Register test with CTest
    # Use get_current_compiler to detect if we're building with Emscripten
    get_current_compiler(CURRENT_COMPILER)
    if(CURRENT_COMPILER STREQUAL "EMSCRIPTEN")
        # For Emscripten tests, we need to generate .js files for Node.js execution
        # Override the global executable suffix for test targets
        set_target_properties(${TARGET_NAME} PROPERTIES
            SUFFIX ".js"  # Generate .js files for Node.js compatibility
        )
        
        # Add Emscripten-specific link options for test executables
        # These can be overridden by setting EMSCRIPTEN_TEST_OPTIONS before calling this function
        if(NOT DEFINED EMSCRIPTEN_TEST_OPTIONS)
            set(EMSCRIPTEN_TEST_OPTIONS
                "SHELL:-s ENVIRONMENT=node"     # Target Node.js environment
                "SHELL:-s EXIT_RUNTIME=1"       # Allow process to exit properly
                "SHELL:-s NODEJS_CATCH_EXIT=0"  # Don't catch exit calls
                "SHELL:-s EXPORTED_RUNTIME_METHODS=['callMain']"  # Export main function
            )
        endif()
        target_link_options(${TARGET_NAME} PRIVATE ${EMSCRIPTEN_TEST_OPTIONS})
        
        # Try to find Node.js executable
        # This can be overridden by setting EMSCRIPTEN_NODE_EXECUTABLE
        if(NOT DEFINED EMSCRIPTEN_NODE_EXECUTABLE)
            set(NODE_EXECUTABLE "node")
            if(DEFINED ENV{EMSDK})
                # Look for Node.js in EMSDK installation - handle both Unix and Windows paths
                if(WIN32)
                    file(GLOB_RECURSE EMSDK_NODE_PATHS "$ENV{EMSDK}/node/*/bin/node.exe")
                else()
                    file(GLOB_RECURSE EMSDK_NODE_PATHS "$ENV{EMSDK}/node/*/bin/node")
                endif()
                if(EMSDK_NODE_PATHS)
                    list(GET EMSDK_NODE_PATHS 0 NODE_EXECUTABLE)
                endif()
            endif()
            
            # Find the Node.js executable if not from EMSDK
            if(NODE_EXECUTABLE STREQUAL "node")
                find_program(NODE_EXECUTABLE node)
                if(NOT NODE_EXECUTABLE)
                    message(WARNING "Node.js not found. Emscripten tests may not run properly.")
                    set(NODE_EXECUTABLE "node")
                endif()
            endif()
            set(EMSCRIPTEN_NODE_EXECUTABLE ${NODE_EXECUTABLE} CACHE STRING "Path to Node.js executable for Emscripten tests")
        endif()
        
        add_test(NAME ${TARGET_NAME} COMMAND ${EMSCRIPTEN_NODE_EXECUTABLE} $<TARGET_FILE:${TARGET_NAME}>)
        # Set working directory to where the test files are located
        set_tests_properties(${TARGET_NAME} PROPERTIES
            WORKING_DIRECTORY $<TARGET_FILE_DIR:${TARGET_NAME}>
        )
    else()
        # For native builds, run the executable directly
        add_test(NAME ${TARGET_NAME} COMMAND ${TARGET_NAME})
    endif()

    # Apply common project options (warnings, sanitizers, static analysis, etc.)
    setup_common_project_options(${TARGET_NAME})

    # Install if requested
    if(ARG_INSTALL)
        install_component(${TARGET_NAME})
    endif()

    message(STATUS "Created test '${TARGET_NAME}' using ${framework_name}")
endfunction()
