# ==============================================================================
# Simple Target Link Dependencies Module
# ==============================================================================
# This module provides a simple target_link_dependencies function that:
# 1. Links dependencies to the target
# 2. Automatically copies shared libraries (.dll on Windows, .so on Linux, .dylib on macOS)
# 3. Installs shared libraries alongside the target

# Simple function to link dependencies and handle all shared library management
# Usage:
#     target_link_dependencies(target_name
#         [PRIVATE|PUBLIC|INTERFACE] 
#         dependency1 dependency2 ...
#         [PRIVATE|PUBLIC|INTERFACE] 
#         dependency3 ...
#     )
function(target_link_dependencies TARGET_NAME)
    if(NOT TARGET_NAME OR NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "target_link_dependencies: Target '${TARGET_NAME}' does not exist")
        return()
    endif()

    set(current_visibility "PRIVATE")  # Default visibility
    
    # First pass: link all dependencies and collect specified targets
    set(specified_targets "")
    foreach(item ${ARGN})
        if(item IN_LIST CMAKE_TARGET_SCOPE_TYPES)
            set(current_visibility ${item})
        else()
            # Link the library
            target_link_libraries(${TARGET_NAME} ${current_visibility} ${item})
            # Collect specified targets for dependency copying
            if(TARGET ${item})
                list(APPEND specified_targets ${item})
            endif()
        endif()
    endforeach()
    
    # Second pass: handle shared library copying and installation for specified targets only
    _target_copy_all_dependencies(${TARGET_NAME} ${specified_targets})
endfunction()

# Internal function to handle all dependency copying (shared libs and external DLLs)
function(_target_copy_all_dependencies TARGET_NAME)
    if(NOT TARGET_NAME OR NOT TARGET ${TARGET_NAME})
        return()
    endif()
    
    # Get the specified targets to process (passed as additional arguments)
    set(targets_to_process ${ARGN})
    if(NOT targets_to_process)
        return()
    endif()
    
    # Collect all shared library dependencies
    set(shared_deps "")
    set(visited_targets "")
    set(external_dlls "")

    # Function to collect all dependency targets recursively
    function(collect_all_deps target_name)
        # Avoid infinite recursion
        if(target_name IN_LIST visited_targets)
            return()
        endif()
        list(APPEND visited_targets ${target_name})
        
        if(TARGET ${target_name})
            get_target_property(target_type ${target_name} TYPE)
            
            # Collect shared libraries
            if(target_type STREQUAL "SHARED_LIBRARY")
                list(APPEND shared_deps ${target_name})
            endif()
            
            # Check for external DLL dependencies based on target properties
            _check_external_dlls(${target_name})
            
            # Check this target's dependencies
            get_target_property(target_deps ${target_name} LINK_LIBRARIES)
            if(target_deps)
                foreach(dep ${target_deps})
                    collect_all_deps(${dep})
                endforeach()
            endif()
            
            # Check interface dependencies
            get_target_property(interface_deps ${target_name} INTERFACE_LINK_LIBRARIES)
            if(interface_deps)
                foreach(dep ${interface_deps})
                    if(TARGET ${dep})
                        collect_all_deps(${dep})
                    endif()
                endforeach()
            endif()
        endif()
        
        # Propagate results back to parent scope
        set(shared_deps ${shared_deps} PARENT_SCOPE)
        set(visited_targets ${visited_targets} PARENT_SCOPE)
        set(external_dlls ${external_dlls} PARENT_SCOPE)
    endfunction()

    foreach(lib ${targets_to_process})
        collect_all_deps(${lib})
    endforeach()
    
    # Remove duplicates
    if(shared_deps)
        list(REMOVE_DUPLICATES shared_deps)
    endif()
    
    # Copy all shared libraries
    foreach(shared_lib ${shared_deps})
        add_custom_command(
            TARGET ${TARGET_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "$<TARGET_FILE:${shared_lib}>"
                "$<TARGET_FILE_DIR:${TARGET_NAME}>"
            COMMENT "Copying shared library: $<TARGET_FILE_NAME:${shared_lib}>"
            VERBATIM
        )
        
        # Install shared library
        install(FILES "$<TARGET_FILE:${shared_lib}>"
            DESTINATION ${CMAKE_INSTALL_BINDIR}
            COMPONENT Runtime
        )
    endforeach()
    
    # Copy external DLLs if any were found
    foreach(dll_info ${external_dlls})
        string(REPLACE "|" ";" dll_parts "${dll_info}")
        list(GET dll_parts 0 dll_path)
        list(GET dll_parts 1 dll_name)
        
        add_custom_command(
            TARGET ${TARGET_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${dll_path}"
                "$<TARGET_FILE_DIR:${TARGET_NAME}>"
            COMMENT "Copying external dependency: ${dll_name}"
            VERBATIM
        )
        
        # Install external DLL
        install(FILES "${dll_path}"
            DESTINATION ${CMAKE_INSTALL_BINDIR}
            COMPONENT Runtime
        )
    endforeach()
endfunction()

# Internal function to check for external DLL dependencies
function(_check_external_dlls target_name)
    if(NOT TARGET ${target_name})
        return()
    endif()
    
    # Check for known libraries with external DLL dependencies
    get_target_property(target_alias ${target_name} ALIASED_TARGET)
    if(target_alias)
        set(check_target ${target_alias})
    else()
        set(check_target ${target_name})
    endif()
    
    # Get target name for comparison
    get_target_property(actual_name ${check_target} NAME)
    if(NOT actual_name)
        set(actual_name ${check_target})
    endif()
    
    # Check for DPP library (Discord++)
    if(actual_name MATCHES "dpp" OR check_target MATCHES "dpp")
        get_target_property(dpp_source_dir ${check_target} SOURCE_DIR)
        if(dpp_source_dir)
            # Look for the win32/bin directory relative to DPP source
            set(dpp_dll_dir "${dpp_source_dir}/../win32/bin")
            get_filename_component(dpp_dll_dir "${dpp_dll_dir}" ABSOLUTE)
            
            if(EXISTS "${dpp_dll_dir}")
                # List of DPP required DLLs
                set(required_dlls
                    "libcrypto-1_1-x64.dll"
                    "libssl-1_1-x64.dll"
                    "libsodium.dll"
                    "opus.dll"
                    "zlib1.dll"
                )
                
                foreach(dll_name ${required_dlls})
                    set(dll_path "${dpp_dll_dir}/${dll_name}")
                    if(EXISTS "${dll_path}")
                        list(APPEND external_dlls "${dll_path}|${dll_name}")
                    endif()
                endforeach()
            endif()
        endif()
    endif()
    
    # Add more libraries here as needed
    # Example for future libraries:
    # elseif(actual_name MATCHES "some_other_lib")
    #     # Handle some_other_lib external DLLs
    
    # Propagate results back to parent scope
    set(external_dlls ${external_dlls} PARENT_SCOPE)
endfunction()
