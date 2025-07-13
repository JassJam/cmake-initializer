# ==============================================================================
# Executable Registration Module
# ==============================================================================
# This module provides the register_executable function for comprehensive
# executable target registration with full visibility control.

# Comprehensive executable registration with visibility control
# usage:
# register_executable(MyExecutable
#     SOURCE_DIR "src"
#     INCLUDE_DIR "include"
#     SOURCES PRIVATE "main.cpp" "utils.cpp" PUBLIC "api.cpp"
#     INCLUDES PRIVATE "private/include" PUBLIC "public/include" INTERFACE "interface/include"
#     LIBRARIES PRIVATE "private_lib" PUBLIC "public_lib" INTERFACE "interface_lib"
#     DEPENDENCIES PRIVATE "dep1" PUBLIC "dep2" INTERFACE "dep3"
#     COMPILE_DEFINITIONS PRIVATE "PRIVATE_DEF" PUBLIC "PUBLIC_DEF" INTERFACE "INTERFACE_DEF"
#     COMPILE_OPTIONS PRIVATE "-Wall" PUBLIC "-O2" INTERFACE "-fPIC"
#     COMPILE_FEATURES PRIVATE "cxx_std_17" PUBLIC "cxx_std_20" INTERFACE "cxx_std_23"
#     LINK_OPTIONS PRIVATE "-static" PUBLIC "-shared" INTERFACE "-fPIC"
#     PROPERTIES "PROPERTY1" "value1" "PROPERTY2" "value2"
#     INSTALL
# )
function(register_executable TARGET_NAME)
    set(options INSTALL DEPENDENCIES)
    set(oneValueArgs SOURCE_DIR INCLUDE_DIR)
    set(multiValueArgs SOURCES INCLUDES LIBRARIES DEPENDENCY_LIST
        COMPILE_DEFINITIONS COMPILE_OPTIONS COMPILE_FEATURES LINK_OPTIONS PROPERTIES)
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

    # Add sources with visibility
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
        # Auto-discover sources
        file(GLOB_RECURSE SOURCES "${ARG_SOURCE_DIR}/*.cpp" "${ARG_SOURCE_DIR}/*.c")
        if(SOURCES)
            target_sources(${TARGET_NAME} PRIVATE ${SOURCES})
        endif()
    endif()

    # Add default include directory
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${ARG_INCLUDE_DIR}")
        target_include_directories(${TARGET_NAME} PRIVATE 
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${ARG_INCLUDE_DIR}>)
    endif()

    # Add includes with visibility
    if(ARG_INCLUDES)
        set(current_visibility "PRIVATE")  # Default visibility
        foreach(item ${ARG_INCLUDES})
            if(item STREQUAL "PRIVATE" OR item STREQUAL "PUBLIC" OR item STREQUAL "INTERFACE")
                set(current_visibility ${item})
            else()
                target_include_directories(${TARGET_NAME} ${current_visibility} ${item})
            endif()
        endforeach()
    endif()

    # Add libraries with visibility (always include common)
    target_link_libraries(${TARGET_NAME} PRIVATE ${THIS_PROJECT_NAMESPACE}::common)
    
    if(ARG_LIBRARIES)
        set(current_visibility "PRIVATE")  # Default visibility
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

    # Configure RPATH for shared library dependencies
    if(UNIX)
        set_target_properties(${TARGET_NAME} PROPERTIES
            # Don't skip the full RPATH for the build tree
            SKIP_BUILD_RPATH FALSE
            # When building, don't use the install RPATH already
            BUILD_WITH_INSTALL_RPATH FALSE
            # Add the automatically determined parts of the RPATH
            # which point to directories outside the build tree to the install RPATH
            INSTALL_RPATH_USE_LINK_PATH TRUE
            # The RPATH to be used when installing - look in same directory as executable
            INSTALL_RPATH "$ORIGIN"
        )
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

    # Install if requested
    if(ARG_INSTALL)
        install_component(${TARGET_NAME})
    endif()
endfunction()
