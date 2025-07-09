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
