# ==============================================================================
# Simple Target Link Dependencies Module
# ==============================================================================
# This module provides a simple target_link_dependencies function that:
# 1. Links dependencies to the target
# 2. Automatically copies shared libraries (.dll on Windows, .so on Linux, .dylib on macOS)
# 3. Installs shared libraries alongside the target

# Simple function to link dependencies and handle shared library copying/installation
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
    
    foreach(item ${ARGN})
        if(item IN_LIST CMAKE_TARGET_SCOPE_TYPES)
            set(current_visibility ${item})
        else()
            # Link the library
            target_link_libraries(${TARGET_NAME} ${current_visibility} ${item})
            
            # If it's a TARGET_NAME, handle shared library copying and installation
            if(TARGET ${item})
                get_target_property(target_type ${item} TYPE)
                
                if(target_type STREQUAL "SHARED_LIBRARY")
                    # Copy shared library to TARGET_NAME output directory during build
                    add_custom_command(
                        TARGET ${TARGET_NAME} POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                            "$<TARGET_FILE:${item}>"
                            "$<TARGET_FILE_DIR:${TARGET_NAME}>"
                        COMMENT "Copying shared library: $<TARGET_FILE_NAME:${item}>"
                        VERBATIM
                    )
                    
                    # Install shared library alongside the TARGET_NAME
                    install(FILES "$<TARGET_FILE:${item}>"
                        DESTINATION ${CMAKE_INSTALL_BINDIR}
                        COMPONENT Runtime
                    )
                endif()
            endif()
        endif()
    endforeach()
endfunction()

# Helper function to recursively copy all shared library dependencies
function(target_copy_all_shared_deps TARGET_NAME)
    if(NOT TARGET_NAME OR NOT TARGET ${TARGET_NAME})
        return()
    endif()
    
    # Get all link libraries for the TARGET_NAME
    get_target_property(target_link_libs ${TARGET_NAME} LINK_LIBRARIES)
    if(NOT target_link_libs)
        return()
    endif()
    
    # Function to collect all dependency targets recursively
    function(collect_shared_deps target_name visited_targets shared_deps)
        # Avoid infinite recursion
        if(target_name IN_LIST visited_targets)
            return()
        endif()
        list(APPEND visited_targets ${target_name})
        
        if(TARGET ${target_name})
            get_target_property(target_type ${target_name} TYPE)
            
            if(target_type STREQUAL "SHARED_LIBRARY")
                list(APPEND shared_deps ${target_name})
            endif()
            
            # Check this TARGET_NAME's dependencies
            get_target_property(target_deps ${target_name} LINK_LIBRARIES)
            if(target_deps)
                foreach(dep ${target_deps})
                    collect_shared_deps(${dep} "${visited_targets}" shared_deps)
                endforeach()
            endif()
            
            # Check interface dependencies
            get_target_property(interface_deps ${target_name} INTERFACE_LINK_LIBRARIES)
            if(interface_deps)
                foreach(dep ${interface_deps})
                    if(TARGET ${dep})
                        collect_shared_deps(${dep} "${visited_targets}" shared_deps)
                    endif()
                endforeach()
            endif()
        endif()
        
        # Propagate results back to parent scope
        set(shared_deps ${shared_deps} PARENT_SCOPE)
        set(visited_targets ${visited_targets} PARENT_SCOPE)
    endfunction()
    
    # Collect all shared library dependencies
    set(all_shared_deps "")
    set(visited_list "")
    foreach(lib ${target_link_libs})
        collect_shared_deps(${lib} "${visited_list}" all_shared_deps)
    endforeach()
    
    # Remove duplicates
    if(all_shared_deps)
        list(REMOVE_DUPLICATES all_shared_deps)
    endif()
    
    # Copy all shared libraries
    foreach(shared_lib ${all_shared_deps})
        add_custom_command(
            TARGET ${TARGET_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "$<TARGET_FILE:${shared_lib}>"
                "$<TARGET_FILE_DIR:${TARGET_NAME}>"
            COMMENT "Auto-copying dependency: $<TARGET_FILE_NAME:${shared_lib}>"
            VERBATIM
        )
        
        # Install shared library
        install(FILES "$<TARGET_FILE:${shared_lib}>"
            DESTINATION ${CMAKE_INSTALL_BINDIR}
            COMPONENT Runtime
        )
    endforeach()
endfunction()

# Function to copy external DLL dependencies (for libraries like DPP that have pre-built DLLs)
function(target_copy_external_dlls TARGET_NAME)
    if(NOT TARGET_NAME OR NOT TARGET ${TARGET_NAME})
        return()
    endif()
    
    # Get all link libraries for the TARGET_NAME
    get_target_property(target_link_libs ${TARGET_NAME} LINK_LIBRARIES)
    if(NOT target_link_libs)
        return()
    endif()
    
    # Check if DPP is linked (it has external DLL dependencies)
    foreach(lib ${target_link_libs})
        if(TARGET ${lib})
            get_target_property(target_name ${lib} NAME)
            if(target_name STREQUAL "dpp" OR lib STREQUAL "dpp")
                # DPP has external DLL dependencies in win32/bin
                get_target_property(dpp_source_dir ${lib} SOURCE_DIR)
                if(dpp_source_dir)
                    # Look for the win32/bin directory relative to DPP source
                    set(dpp_dll_dir "${dpp_source_dir}/../win32/bin")
                    get_filename_component(dpp_dll_dir "${dpp_dll_dir}" ABSOLUTE)
                    
                    if(EXISTS "${dpp_dll_dir}")
                        # Copy the required DLLs
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
                                add_custom_command(
                                    TARGET ${TARGET_NAME} POST_BUILD
                                    COMMAND ${CMAKE_COMMAND} -E copy_if_different
                                        "${dll_path}"
                                        "$<TARGET_FILE_DIR:${TARGET_NAME}>"
                                    COMMENT "Copying DPP external dependency: ${dll_name}"
                                    VERBATIM
                                )
                                
                                # Install external DLL
                                install(FILES "${dll_path}"
                                    DESTINATION ${CMAKE_INSTALL_BINDIR}
                                    COMPONENT Runtime
                                )
                            endif()
                        endforeach()
                    endif()
                endif()
                break()
            endif()
        endif()
    endforeach()
endfunction()

# Enhanced version that also handles transitive dependencies automatically
function(target_link_dependencies_auto TARGET_NAME)
    target_link_dependencies(${TARGET_NAME} ${ARGN})
    target_copy_all_shared_deps(${TARGET_NAME})
    target_copy_external_dlls(${TARGET_NAME})
endfunction()
