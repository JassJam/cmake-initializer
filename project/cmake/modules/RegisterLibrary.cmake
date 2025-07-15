# ==============================================================================
# Library Registration Module
# ==============================================================================
# This module provides the register_library function for comprehensive
# library target registration with full visibility control.

# Comprehensive library registration with visibility control
# usage:
# register_library(MyLibrary
#     SHARED|STATIC|INTERFACE
#     SOURCE_DIR "src"
#     INCLUDE_DIR "include"
#     SOURCES PRIVATE "lib.cpp" "utils.cpp" PUBLIC "api.cpp"
#     INCLUDES PRIVATE "private/include" PUBLIC "public/include" INTERFACE "interface/include"
#     LIBRARIES PRIVATE "private_lib" PUBLIC "public_lib" INTERFACE "interface_lib"
#     DEPENDENCIES PRIVATE "dep1" PUBLIC "dep2" INTERFACE "dep3"
#     COMPILE_DEFINITIONS PRIVATE "PRIVATE_DEF" PUBLIC "PUBLIC_DEF" INTERFACE "INTERFACE_DEF"
#     COMPILE_OPTIONS PRIVATE "-Wall" PUBLIC "-O2" INTERFACE "-fPIC"
#     COMPILE_FEATURES PRIVATE "cxx_std_17" PUBLIC "cxx_std_20" INTERFACE "cxx_std_23"
#     LINK_OPTIONS PRIVATE "-static" PUBLIC "-shared" INTERFACE "-fPIC"
#     PROPERTIES "PROPERTY1" "value1" "PROPERTY2" "value2"
#     EXPORT_MACRO "MY_EXPORT"
#     ENVIRONMENT [dev|prod|test|...]
#     INSTALL
# )
function(register_library TARGET_NAME)
    set(options SHARED STATIC INTERFACE INSTALL DEPENDENCIES)
    set(oneValueArgs SOURCE_DIR INCLUDE_DIR EXPORT_MACRO ENVIRONMENT)
    set(multiValueArgs SOURCES INCLUDES LIBRARIES DEPENDENCY_LIST
        COMPILE_DEFINITIONS COMPILE_OPTIONS COMPILE_FEATURES LINK_OPTIONS PROPERTIES)
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

    # Load .env and .env.<ENVIRONMENT> if ENVIRONMENT is set
    set(_env_file "${CMAKE_CURRENT_LIST_DIR}/.env")
    include(LoadEnvVariable)
    target_load_env_files(${TARGET_NAME} "${_env_file}" "${_env_file}.${ARG_ENVIRONMENT}")

    # Add sources with visibility (only for non-interface libraries)
    if(NOT ARG_INTERFACE)
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

        # Add headers for shared libraries
        if(ARG_SHARED)
            file(GLOB_RECURSE HEADERS "${ARG_INCLUDE_DIR}/*.hpp" "${ARG_INCLUDE_DIR}/*.h")
            if(HEADERS)
                set_target_properties(${TARGET_NAME} PROPERTIES PUBLIC_HEADER "${HEADERS}")
            endif()
        endif()
    endif()

    # Add default include directory
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

    # Add includes with visibility
    if(ARG_INCLUDES)
        set(current_visibility "PUBLIC")  # Default visibility for libraries
        if(ARG_INTERFACE)
            set(current_visibility "INTERFACE")
        endif()
        foreach(item ${ARG_INCLUDES})
            if(item STREQUAL "PRIVATE" OR item STREQUAL "PUBLIC" OR item STREQUAL "INTERFACE")
                set(current_visibility ${item})
            else()
                target_include_directories(${TARGET_NAME} ${current_visibility} ${item})
            endif()
        endforeach()
    endif()

    # Add libraries with visibility
    set(DEFAULT_LINK_TYPE PUBLIC)
    if(ARG_INTERFACE)
        set(DEFAULT_LINK_TYPE INTERFACE)
    endif()
    
    # Always link common library
    target_link_libraries(${TARGET_NAME} ${DEFAULT_LINK_TYPE} ${THIS_PROJECT_NAMESPACE}::common)
    
    if(ARG_LIBRARIES)
        set(current_visibility ${DEFAULT_LINK_TYPE})  # Default visibility
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
        set(current_visibility ${DEFAULT_LINK_TYPE})  # Default visibility
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
        set(current_visibility ${DEFAULT_LINK_TYPE})  # Default visibility
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
        set(current_visibility ${DEFAULT_LINK_TYPE})  # Default visibility
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
        set(current_visibility ${DEFAULT_LINK_TYPE})  # Default visibility
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
