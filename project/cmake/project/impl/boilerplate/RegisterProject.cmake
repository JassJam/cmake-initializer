# ==============================================================================
# Project Organization Module
# ==============================================================================
# This module provides the register_project function for project structure
# organization and batch target creation.

# Simple project setup - reduces boilerplate in subdirectories
# usage:
# register_project(NAME "MyProject"
#     SUBDIRS "subdir1" "subdir2"
#     EXECUTABLES "MyApp1" "MyApp2"
#     LIBRARIES "MyLib1" "MyLib2"
# )
function(register_project)
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
            register_executable(${exe} INSTALL)
        endforeach()
    endif()

    if(ARG_LIBRARIES)
        foreach(lib ${ARG_LIBRARIES})
            register_library(${lib} INSTALL)
        endforeach()
    endif()
endfunction()
