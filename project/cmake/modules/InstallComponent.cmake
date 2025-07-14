include(CMakePackageConfigHelpers)

#
# Helper function to install a target with specific components
# This function installs a target with the specified components and options.
# It handles the installation of runtime, library, and archive files,
# as well as public headers and export configuration.
# It also generates export headers for shared libraries.
#
# usage:
# install_component(target
#     [INCLUDE_SUBDIR <subdir>]
#     [NAMESPACE <namespace>]
#     [RUNTIME_DIR <runtime_dir>]
#     [LIBRARY_DIR <library_dir>]
#     [ARCHIVE_DIR <archive_dir>]
#     [EXPORT_MACRO_NAME <macro_name>]
#     [EXPORT_FILE_NAME <file_name>]
# )
#
# Arguments:
#   target: The target to install.
#   INCLUDE_SUBDIR: The subdirectory under the include directory where the public headers will be installed.
#   NAMESPACE: The namespace to use for the exported targets.
#   RUNTIME_DIR: The directory where runtime files (DLLs and executables) will be installed.
#   LIBRARY_DIR: The directory where library files (shared libraries) will be installed.
#   ARCHIVE_DIR: The directory where archive files (static/import libraries) will be installed.
#   EXPORT_MACRO_NAME: The name of the export define for the target.
#   EXPORT_FILE_NAME: The name of the export file to be generated.
#
# Example:
#   install_component(my_target
#       INCLUDE_SUBDIR "my_subdir"
#       NAMESPACE "my_namespace::"
#       RUNTIME_DIR "bin"
#       LIBRARY_DIR "lib"
#       ARCHIVE_DIR "lib"
#       EXPORT_MACRO_NAME "MYTARGET_EXPORT"
#       EXPORT_FILE_NAME "my_target_export.h"
#   )
#
function(install_component target)
    # Parse arguments
    set(oneValueArgs 
        INCLUDE_SUBDIR 
        NAMESPACE 
        RUNTIME_DIR 
        LIBRARY_DIR 
        ARCHIVE_DIR
        EXPORT_MACRO_NAME
        EXPORT_FILE_NAME
    )
    cmake_parse_arguments(ARG "" "${oneValueArgs}" "" ${ARGN})

    # Set defaults
    if (NOT ARG_INCLUDE_SUBDIR)
        set(ARG_INCLUDE_SUBDIR ${target})
    endif()
    if (NOT ARG_NAMESPACE)
        set(ARG_NAMESPACE ${THIS_PROJECT_NAMESPACE})
    endif()
    if (NOT ARG_RUNTIME_DIR)
        set(ARG_RUNTIME_DIR ${CMAKE_INSTALL_BINDIR})
    endif()
    if (NOT ARG_LIBRARY_DIR)
        set(ARG_LIBRARY_DIR ${CMAKE_INSTALL_LIBDIR})
    endif()
    if (NOT ARG_ARCHIVE_DIR)
        set(ARG_ARCHIVE_DIR ${CMAKE_INSTALL_LIBDIR})
    endif()
    if (NOT ARG_EXPORT_MACRO_NAME)
        set(ARG_EXPORT_MACRO_NAME "${target}_EXPORT")
    endif()
    if (NOT ARG_EXPORT_FILE_NAME)
        set(ARG_EXPORT_FILE_NAME "${ARG_INCLUDE_SUBDIR}/${target}_export.h")
    endif()

    # Get target type
    get_target_property(target_type ${target} TYPE)

    # Install target with appropriate components
    install(TARGETS ${target}
        EXPORT ${target}Targets
        RUNTIME DESTINATION ${ARG_RUNTIME_DIR}  # DLLs and executables
        LIBRARY DESTINATION ${ARG_RUNTIME_DIR}  # Shared libraries (same as executables)
        ARCHIVE DESTINATION ${ARG_ARCHIVE_DIR}  # Static/import libraries
        PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${ARG_INCLUDE_SUBDIR}
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )
    
    # Handle Emscripten WebAssembly files
    include(GetCurrentCompiler)
    get_current_compiler(CURRENT_COMPILER)
    if(CURRENT_COMPILER STREQUAL "EMSCRIPTEN")
        get_target_property(target_type ${target} TYPE)
        if(target_type STREQUAL "EXECUTABLE")
            # Install accompanying WASM files for Emscripten executables
            install(FILES 
                $<TARGET_FILE_DIR:${target}>/$<TARGET_FILE_BASE_NAME:${target}>.wasm
                DESTINATION ${ARG_RUNTIME_DIR}
                OPTIONAL
            )
        endif()
    endif()

    # Install export configuration
    install(EXPORT ${target}Targets
        FILE ${target}Config.cmake
        NAMESPACE ${ARG_NAMESPACE}
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${THIS_PROJECT_NAME}
    )

    # Handle shared library specifics
    if (${target_type} STREQUAL "SHARED_LIBRARY")
        # Generate export headers
        generate_export_header(${target}
            BASE_NAME ${target}
            EXPORT_MACRO_NAME ${ARG_EXPORT_MACRO_NAME}
            EXPORT_FILE_NAME "${CMAKE_CURRENT_BINARY_DIR}/include/${ARG_EXPORT_FILE_NAME}"
        )

        # Install export headers
        install(FILES 
            ${CMAKE_CURRENT_BINARY_DIR}/include/${ARG_EXPORT_FILE_NAME}
            DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${ARG_INCLUDE_SUBDIR}
        )
    endif()
endfunction()