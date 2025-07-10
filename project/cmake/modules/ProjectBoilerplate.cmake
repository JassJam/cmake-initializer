# Simple executable with common defaults
# usage:
# simple_executable(MyExecutable
#     SOURCE_DIR "src"
#     INCLUDE_DIR "include"
#     SOURCES "main.cpp" "utils.cpp"
#     INCLUDES "external/include"
#     LIBRARIES "mylib" "anotherlib"
#     DEPENDENCIES "MyDependency"
#     INSTALL
# )
function(simple_executable TARGET_NAME)
    set(options INSTALL DEPENDENCIES)
    set(oneValueArgs SOURCE_DIR INCLUDE_DIR)
    set(multiValueArgs SOURCES INCLUDES LIBRARIES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Set defaults
    if(NOT ARG_SOURCE_DIR)
        set(ARG_SOURCE_DIR "src")
    endif()
    if(NOT ARG_INCLUDE_DIR)
        set(ARG_INCLUDE_DIR "include")
    endif()

    # Create executable
    add_executable(${TARGET_NAME})

    # Add sources (auto-discover if not specified)
    if(ARG_SOURCES)
        target_sources(${TARGET_NAME} PRIVATE ${ARG_SOURCES})
    else()
        file(GLOB_RECURSE SOURCES "${ARG_SOURCE_DIR}/*.cpp" "${ARG_SOURCE_DIR}/*.c")
        target_sources(${TARGET_NAME} PRIVATE ${SOURCES})
    endif()

    # Add includes
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${ARG_INCLUDE_DIR}")
        target_include_directories(${TARGET_NAME} PRIVATE 
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${ARG_INCLUDE_DIR}>)
    endif()
    
    if(ARG_INCLUDES)
        target_include_directories(${TARGET_NAME} PRIVATE ${ARG_INCLUDES})
    endif()

    # Link common + additional libraries
    target_link_libraries(${TARGET_NAME} PRIVATE 
        ${THIS_PROJECT_NAMESPACE}::common
        ${ARG_LIBRARIES})

    # Load dependencies if specified
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

    # Install if requested
    if(ARG_INSTALL)
        install_component(${TARGET_NAME})
    endif()
endfunction()

# Simple library with common defaults
# usage:
# simple_library(MyLibrary
#     SOURCE_DIR "src"
#     INCLUDE_DIR "include"
#     SOURCES "mylib.cpp" "utils.cpp"
#     INCLUDES "external/include"
#     LIBRARIES "mylib" "anotherlib"
#     DEPENDENCIES "MyDependency"
#     INSTALL
# )
function(simple_library TARGET_NAME)
    set(options SHARED STATIC INTERFACE INSTALL DEPENDENCIES)
    set(oneValueArgs SOURCE_DIR INCLUDE_DIR EXPORT_MACRO)
    set(multiValueArgs SOURCES INCLUDES LIBRARIES PUBLIC_LIBRARIES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Determine library type
    if(ARG_SHARED)
        set(LIB_TYPE SHARED)
    elseif(ARG_STATIC)
        set(LIB_TYPE STATIC)
    elseif(ARG_INTERFACE)
        set(LIB_TYPE INTERFACE)
    else()
        set(LIB_TYPE STATIC)  # Default to static
    endif()

    # Set defaults
    if(NOT ARG_SOURCE_DIR)
        set(ARG_SOURCE_DIR "src")
    endif()
    if(NOT ARG_INCLUDE_DIR)
        set(ARG_INCLUDE_DIR "include")
    endif()

    # Create library
    add_library(${TARGET_NAME} ${LIB_TYPE})

    # Handle interface libraries differently
    if(NOT ARG_INTERFACE)
        # Add sources (auto-discover if not specified)
        if(ARG_SOURCES)
            target_sources(${TARGET_NAME} PRIVATE ${ARG_SOURCES})
        else()
            file(GLOB_RECURSE SOURCES "${ARG_SOURCE_DIR}/*.cpp" "${ARG_SOURCE_DIR}/*.c")
            if(SOURCES)
                target_sources(${TARGET_NAME} PRIVATE ${SOURCES})
            endif()
        endif()

        # Add headers for shared libraries
        if(ARG_SHARED)
            file(GLOB_RECURSE HEADERS "${ARG_INCLUDE_DIR}/*.hpp" "${ARG_INCLUDE_DIR}/*.h")
            if(HEADERS)
                set_target_properties(${TARGET_NAME} PROPERTIES PUBLIC_HEADER "${HEADERS}")
            endif()
        endif()
    endif()

    # Add includes
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${ARG_INCLUDE_DIR}")
        if(ARG_INTERFACE)
            target_include_directories(${TARGET_NAME} INTERFACE 
                $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${ARG_INCLUDE_DIR}>
                $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/${TARGET_NAME}>)
        else()
            target_include_directories(${TARGET_NAME} PUBLIC 
                $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${ARG_INCLUDE_DIR}>
                $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/${ARG_INCLUDE_DIR}>
                $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/${TARGET_NAME}>)
        endif()
    endif()
    
    if(ARG_INCLUDES)
        target_include_directories(${TARGET_NAME} PUBLIC ${ARG_INCLUDES})
    endif()

    # Link libraries
    set(LINK_TYPE PUBLIC)
    if(ARG_INTERFACE)
        set(LINK_TYPE INTERFACE)
    endif()
    
    target_link_libraries(${TARGET_NAME} ${LINK_TYPE}
        ${THIS_PROJECT_NAMESPACE}::common
        ${ARG_PUBLIC_LIBRARIES}
        ${ARG_LIBRARIES})

    # Load dependencies if specified
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

    # Install if requested
    if(ARG_INSTALL)
        if(ARG_EXPORT_MACRO)
            install_component(${TARGET_NAME} 
                INCLUDE_SUBDIR ${TARGET_NAME}
                EXPORT_MACRO_NAME ${ARG_EXPORT_MACRO})
        else()
            install_component(${TARGET_NAME} INCLUDE_SUBDIR ${TARGET_NAME})
        endif()
    endif()
endfunction()

# Simple project setup - reduces boilerplate in subdirectories
# Usage:
# simple_project(NAME "MyProject"
#     SUBDIRS "subdir1" "subdir2"
#     EXECUTABLES "MyApp1" "MyApp2"
#     LIBRARIES "MyLib1" "MyLib2"
# )
function(simple_project)
    set(oneValueArgs NAME)
    set(multiValueArgs SUBDIRS EXECUTABLES LIBRARIES)
    cmake_parse_arguments(ARG "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(ARG_SUBDIRS)
        foreach(subdir ${ARG_SUBDIRS})
            add_subdirectory(${subdir})
        endforeach()
    endif()

    if(ARG_EXECUTABLES)
        foreach(exe ${ARG_EXECUTABLES})
            simple_executable(${exe} INSTALL)
        endforeach()
    endif()

    if(ARG_LIBRARIES)
        foreach(lib ${ARG_LIBRARIES})
            simple_library(${lib} INSTALL)
        endforeach()
    endif()
endfunction()

# ==============================================================================
# Testing Framework Registration System
# ==============================================================================

# Global variables to store test framework configuration
set_property(GLOBAL PROPERTY TEST_FRAMEWORK_REGISTERED FALSE)
set_property(GLOBAL PROPERTY TEST_FRAMEWORK_NAME "")
set_property(GLOBAL PROPERTY TEST_FRAMEWORK_LIBRARIES "")

# Register a test framework globally (call once in main CMakeLists.txt)
# Usage:
# register_test_framework("doctest") (or "catch2", "gtest", "boost")
function(register_test_framework FRAMEWORK_NAME)
    get_property(already_registered GLOBAL PROPERTY TEST_FRAMEWORK_REGISTERED)
    if(already_registered)
        message(WARNING "Test framework already registered. Skipping duplicate registration.")
        return()
    endif()

    message(STATUS "Registering test framework: ${FRAMEWORK_NAME}")
    
    # Set up framework-specific configuration
    if(FRAMEWORK_NAME STREQUAL "doctest")
        CPMAddPackage("gh:doctest/doctest@2.4.11")
        set(FRAMEWORK_LIBS doctest::doctest)
        set(FRAMEWORK_DEFS "DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN")
        
    elseif(FRAMEWORK_NAME STREQUAL "catch2")
        CPMAddPackage("gh:catchorg/Catch2@3.5.2")
        set(FRAMEWORK_LIBS Catch2::Catch2WithMain)
        set(FRAMEWORK_DEFS "")
        
    elseif(FRAMEWORK_NAME STREQUAL "gtest")
        CPMAddPackage("gh:google/googletest@1.14.0")
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

# Simple test creation function - uses the registered test framework
# Usage:
# simple_test(MyTest
#     SOURCE_DIR "tests"
#     SOURCES "test_main.cpp" "test_utils.cpp"
#     LIBRARIES "MyLib"
#     INSTALL
# )
function(simple_test TARGET_NAME)
    set(options INSTALL)
    set(oneValueArgs SOURCE_DIR)
    set(multiValueArgs SOURCES LIBRARIES)
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

    # Add test sources
    if(ARG_SOURCES)
        target_sources(${TARGET_NAME} PRIVATE ${ARG_SOURCES})
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

    # Link test framework and additional libraries
    target_link_libraries(${TARGET_NAME} PRIVATE
        ${framework_libs}
        ${ARG_LIBRARIES}
        ${THIS_PROJECT_NAMESPACE}::common
    )

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
    add_test(NAME ${TARGET_NAME} COMMAND ${TARGET_NAME})

    # Install if requested
    if(ARG_INSTALL)
        install_component(${TARGET_NAME})
    endif()

    message(STATUS "Created test '${TARGET_NAME}' using ${framework_name}")
endfunction()
