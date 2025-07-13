include(CPMDownloader)
include(StringListInterpolation)

#
# Dependency management function for CMake projects using CPM
# Usage:
#     target_add_dependency(target_name
#         PACKAGES
#             package1 
#                 [URL url1] 
#                 [HASH hash1]
#                 [GIT_REPOSITORY repo_url]
#                 [GIT_TAG tag_or_commit]
#                 [GITHUB_REPOSITORY owner/repo]
#                 [VERSION version]
#                 [OPTIONS "option1 value1" "option2 value2"] 
#                 [LINK_TARGETS "target1 PRIVATE" "target2 PUBLIC" ...] 
#                 [LINK_TYPE PRIVATE|PUBLIC|INTERFACE] 
#                 [INSTALL_TYPE NONE|SHARED|ALL]
#                 [INSTALL_VERSION version_for_paths]
#                 [COMPONENT component]
#                 [DOWNLOAD_ONLY YES|NO]
#             package2 ...
#     )
#
function(target_add_dependency target)
    # parse arguments
    set(options)
    set(oneValueArgs)
    set(multiValueArgs PACKAGES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    set(current_package "")
    set(package_params "")
    set(package_link_type "PRIVATE")
    set(package_link_targets "")
    set(package_install_type "SHARED")
    set(package_install_version "")
    set(package_component "dependencies")
    set(package_download_only "NO")
    set(packages_to_process "")
    
    # process all arguments
    foreach(arg ${ARG_PACKAGES})
        if (arg STREQUAL "URL" OR 
             arg STREQUAL "HASH" OR 
             arg STREQUAL "GIT_REPOSITORY" OR 
             arg STREQUAL "GIT_TAG" OR 
             arg STREQUAL "GITHUB_REPOSITORY" OR 
             arg STREQUAL "VERSION" OR 
             arg STREQUAL "OPTIONS")
            # These are passed directly to CPM
            set(expect ${arg})
        elseif (arg STREQUAL "LINK_TYPE")
            set(expect "LINK_TYPE")
        elseif (arg STREQUAL "LINK_TARGETS")
            set(expect "LINK_TARGETS")
        elseif (arg STREQUAL "INSTALL_TYPE")
            set(expect "INSTALL_TYPE")
        elseif (arg STREQUAL "INSTALL_VERSION")
            set(expect "INSTALL_VERSION")
        elseif (arg STREQUAL "COMPONENT")
            set(expect "COMPONENT")
        elseif (arg STREQUAL "DOWNLOAD_ONLY")
            set(expect "DOWNLOAD_ONLY")
        elseif (DEFINED expect)
            if (expect STREQUAL "LINK_TYPE")
                set(package_link_type ${arg})
            elseif (expect STREQUAL "LINK_TARGETS")
                list(APPEND package_link_targets "${arg}")
            elseif (expect STREQUAL "INSTALL_TYPE")
                set(package_install_type ${arg})
            elseif (expect STREQUAL "INSTALL_VERSION")
                set(package_install_version ${arg})
            elseif (expect STREQUAL "COMPONENT")
                set(package_component ${arg})
            elseif (expect STREQUAL "DOWNLOAD_ONLY")
                set(package_download_only ${arg})
            else()
                # Add to CPM parameters
                list(APPEND package_params "${expect}" "${arg}")
            endif()
            set(expect "")
        else()
            # If we have a current package, add it to the processing list
            if (NOT "${current_package}" STREQUAL "")
                list_to_string("${package_link_targets}" "{{SEMICOLON}}" package_link_targets)
                list_to_string("${package_params}" "{{SEMICOLON}}" package_params)

                # Format: name|CPM params|link type|link targets|install type|install version|component|download only
                list(APPEND packages_to_process 
                    "${current_package}|${package_params}|${package_link_type}|${package_link_targets}|${package_install_type}|${package_install_version}|${package_component}|${package_download_only}")
                
                # Reset for next package
                set(package_params "")
                set(package_link_type "PRIVATE")
                set(package_link_targets "")
                set(package_install_type "SHARED")
                set(package_install_version "")
                set(package_component "dependencies")
                set(package_download_only "NO")
            endif()
            set(current_package ${arg})
        endif()
    endforeach()
    
    # Add the last package
    if (NOT "${current_package}" STREQUAL "")
        list_to_string("${package_link_targets}" "{{SEMICOLON}}" package_link_targets)
        list_to_string("${package_params}" "{{SEMICOLON}}" package_params)

        # Format: name|CPM params|link type|link targets|install type|install version|component|download only
        list(APPEND packages_to_process 
            "${current_package}|${package_params}|${package_link_type}|${package_link_targets}|${package_install_type}|${package_install_version}|${package_component}|${package_download_only}")
    endif()

    message(STATUS "Processing dependencies for target: ${target}")
    message(STATUS "packages_to_process: ${packages_to_process}")
    
    # Process all packages
    foreach(package_info ${packages_to_process})
        string(REPLACE "|" ";" package_parts "${package_info}")
        
        # Extract package information
        list(LENGTH package_parts num_parts)
        list(GET package_parts 0 pkg_name)
        list(GET package_parts 1 pkg_params)
        list(GET package_parts 2 pkg_link_type)
        list(GET package_parts 3 pkg_link_targets_escaped)
        list(GET package_parts 4 pkg_install_type)
        list(GET package_parts 5 pkg_install_version)
        list(GET package_parts 6 pkg_component)
        list(GET package_parts 7 pkg_download_only)
        
        # Unescape the link targets
        string(REPLACE "{{SEMICOLON}}" ";" pkg_link_targets "${pkg_link_targets_escaped}")
        
        _process_and_install_package(
            ${target} 
            ${pkg_name} 
            ${pkg_params} 
            "${pkg_link_type}" 
            "${pkg_link_targets}"
            "${pkg_install_type}" 
            "${pkg_install_version}"
            "${pkg_component}"
            "${pkg_download_only}"
        )
    endforeach()
endfunction()

# Helper function to process a single package and handle installation
function(_process_and_install_package target pkg_name pkg_params_string pkg_link_type pkg_link_targets pkg_install_type pkg_install_version pkg_component pkg_download_only)
    string_to_list("${pkg_params_string}" "{{SEMICOLON}}" pkg_params)
    
    # Extract version if specified for find_package
    set(pkg_version "")
    list(LENGTH pkg_params param_length)
    set(i 0)
    while(i LESS param_length)
        list(GET pkg_params ${i} param_name)
        math(EXPR i "${i}+1")
        if (i LESS param_length)
            list(GET pkg_params ${i} param_value)
            if (param_name STREQUAL "VERSION")
                set(pkg_version ${param_value})
            endif()
            math(EXPR i "${i}+1")
        endif()
    endwhile()
    
    message(STATUS "Adding dependency: ${pkg_name} (${pkg_link_type}, install: ${pkg_install_type})")
    
    set(found_via_findpackage FALSE)
    if (NOT FORCE_CPM_DOWNLOAD AND NOT pkg_download_only STREQUAL "YES")
        # Convert package name for find_package (replace - with _)
        string(REPLACE "-" "_" find_pkg_name ${pkg_name})
        string(TOUPPER ${find_pkg_name} find_pkg_name_upper)
        
        # Try to find the package using find_package
        if (pkg_version)
            find_package(${pkg_name} ${pkg_version} QUIET)
        else()
            find_package(${pkg_name} QUIET)
        endif()
        
        # Check if found by testing common variables
        if (${pkg_name}_FOUND OR ${find_pkg_name}_FOUND OR ${find_pkg_name_upper}_FOUND)
            message(STATUS "    Found ${pkg_name} via find_package")
            set(found_via_findpackage TRUE)
        endif()
    endif()
    
    # If not found via find_package, use CPM
    if (NOT found_via_findpackage)
        # Build the CPMAddPackage call dynamically
        set(cpm_args "NAME" "${pkg_name}")
        foreach(param ${pkg_params})
            list(APPEND cpm_args "${param}")
        endforeach()
        
        if (pkg_download_only STREQUAL "YES")
            list(APPEND cpm_args "DOWNLOAD_ONLY" "YES")
        endif()
        
        CPMAddPackage(${cpm_args})
    endif()
    
    # For download-only packages, no need to link or install
    if (pkg_download_only STREQUAL "YES")
        return()
    endif()
    
    # Check if we have specific link targets defined
    if (pkg_link_targets)
        message(STATUS "    Using custom link targets for ${pkg_name}")
        foreach(link_target_info ${pkg_link_targets})
            # Parse the target name and link type
            string(REGEX MATCH "([^ ]+) +([A-Z]+)" match "${link_target_info}")
            if (match)
                set(link_target_name "${CMAKE_MATCH_1}")
                set(link_target_type "${CMAKE_MATCH_2}")
            else()
                # If no link type specified, use the default
                set(link_target_name "${link_target_info}")
                set(link_target_type "${pkg_link_type}")
            endif()
            
            # Check if the target exists
            if (TARGET ${link_target_name})
                # Link the target
                target_link_libraries(${target}
                    ${link_target_type}
                        ${link_target_name}
                )
                
                # For installation, we need to track which targets we're using
                list(APPEND used_targets ${link_target_name})
            else()
                message(WARNING "    Custom link target ${link_target_name} not found")
            endif()
        endforeach()
    else()
        # Default linking behavior
        # Try to determine the actual targets to link against
        set(found_targets FALSE)
        
        # Common known package patterns
        if (pkg_name STREQUAL "Catch2")
            # Special case for Catch2
            if (TARGET Catch2::Catch2WithMain)
                target_link_libraries(${target} ${pkg_link_type} Catch2::Catch2WithMain)
                set(found_targets TRUE)
                list(APPEND used_targets Catch2::Catch2WithMain)
            elseif (TARGET Catch2::Catch2)
                target_link_libraries(${target} ${pkg_link_type} Catch2::Catch2)
                set(found_targets TRUE)
                list(APPEND used_targets Catch2::Catch2)
            endif()
        elseif (pkg_name STREQUAL "GTest" OR pkg_name STREQUAL "googletest")
            # Special case for GTest
            if (TARGET GTest::gtest_main)
                target_link_libraries(${target} ${pkg_link_type} GTest::gtest_main)
                set(found_targets TRUE)
                list(APPEND used_targets GTest::gtest_main)
            elseif (TARGET GTest::gtest)
                target_link_libraries(${target} ${pkg_link_type} GTest::gtest GTest::gtest_main)
                set(found_targets TRUE)
                list(APPEND used_targets GTest::gtest GTest::gtest_main)
            endif()
        elseif (pkg_name STREQUAL "Boost")
            # Special case for Boost (requires components)
            # User should specify Boost components using LINK_TARGETS
            message(STATUS "    Boost detected. Please specify components using LINK_TARGETS")
            set(found_targets TRUE) # Don't try default linking
        else()
            # Try common target naming patterns
            
            # 1. Direct target name
            if (TARGET ${pkg_name})
                target_link_libraries(${target} ${pkg_link_type} ${pkg_name})
                set(found_targets TRUE)
                list(APPEND used_targets ${pkg_name})
                
            # 2. Namespaced target
            elseif (TARGET ${pkg_name}::${pkg_name})
                target_link_libraries(${target} ${pkg_link_type} ${pkg_name}::${pkg_name})
                set(found_targets TRUE)
                list(APPEND used_targets ${pkg_name}::${pkg_name})
                
            # 3. Common alternative naming
            else()
                # Try with underscore instead of dash
                string(REPLACE "-" "_" alt_pkg_name ${pkg_name})
                if (TARGET ${alt_pkg_name})
                    target_link_libraries(${target} ${pkg_link_type} ${alt_pkg_name})
                    set(found_targets TRUE)
                    list(APPEND used_targets ${alt_pkg_name})
                elseif (TARGET ${alt_pkg_name}::${alt_pkg_name})
                    target_link_libraries(${target} ${pkg_link_type} ${alt_pkg_name}::${alt_pkg_name})
                    set(found_targets TRUE)
                    list(APPEND used_targets ${alt_pkg_name}::${alt_pkg_name})
                endif()
            endif()
        endif()
        
        if (NOT found_targets)
            message(WARNING "No suitable targets found for ${pkg_name}. Use LINK_TARGETS to specify explicitly.")
            return()
        endif()
    endif()
    
    # Use version for installation paths
    set(install_version "")
    if (pkg_install_version)
        set(install_version ${pkg_install_version})
    elseif (pkg_version)
        set(install_version ${pkg_version})
    endif()
    
    # Handle installation based on the install type
    if (NOT pkg_install_type STREQUAL "NONE")
        # Determine installation paths with versioning
        set(lib_install_dir ${CMAKE_INSTALL_LIBDIR})
        set(bin_install_dir ${CMAKE_INSTALL_BINDIR})
        set(include_install_dir ${CMAKE_INSTALL_INCLUDEDIR})
        
        # Add version to path if specified
        if (install_version)
            set(lib_install_dir "${lib_install_dir}/${pkg_name}-${install_version}")
            set(bin_install_dir "${bin_install_dir}/${pkg_name}-${install_version}")
            set(include_install_dir "${include_install_dir}/${pkg_name}-${install_version}")
        endif()
        
        # Install libraries for each used target
        foreach(link_target ${used_targets})
            if (TARGET ${link_target})
                get_target_property(target_type ${link_target} TYPE)
                
                # Handle shared libraries
                if (target_type STREQUAL "SHARED_LIBRARY")
                    # Copy DLLs for Windows during development
                    if (WIN32)
                        add_custom_command(
                            TARGET ${target} POST_BUILD
                            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                                $<TARGET_FILE:${link_target}>
                                $<TARGET_FILE_DIR:${target}>
                            COMMENT "Copying ${link_target} DLL to output directory..."
                        )
                    endif()
                    
                    # Install the library files
                    install(FILES $<TARGET_FILE:${link_target}>
                        DESTINATION ${bin_install_dir}
                        COMPONENT ${pkg_component}
                    )
                    
                    # On non-Windows, also need to install the .so symlinks
                    if (UNIX AND NOT APPLE)
                        get_target_property(lib_version ${link_target} VERSION)
                        get_target_property(lib_soversion ${link_target} SOVERSION)
                        
                        if (lib_soversion)
                            install(FILES $<TARGET_SONAME_FILE:${link_target}>
                                DESTINATION ${bin_install_dir}
                                COMPONENT ${pkg_component}
                            )
                        endif()
                    endif()
                endif()
                
                # For INSTALL_TYPE ALL, install static libraries too
                if (pkg_install_type STREQUAL "ALL" AND target_type STREQUAL "STATIC_LIBRARY")
                    install(FILES $<TARGET_FILE:${link_target}>
                        DESTINATION ${lib_install_dir}
                        COMPONENT ${pkg_component}
                    )
                endif()
            endif()
        endforeach()
        
        # If INSTALL_TYPE is ALL, also install headers
        if (pkg_install_type STREQUAL "ALL")
            # If we have access to the package source dir, install headers too
            if (DEFINED ${pkg_name}_SOURCE_DIR)
                file(GLOB_RECURSE header_files 
                    "${${pkg_name}_SOURCE_DIR}/include/*.h" 
                    "${${pkg_name}_SOURCE_DIR}/include/*.hpp"
                    "${${pkg_name}_SOURCE_DIR}/include/*.hxx"
                    "${${pkg_name}_SOURCE_DIR}/include/*.h++"
                )
                if (header_files)
                    install(FILES ${header_files}
                        DESTINATION ${include_install_dir}
                        COMPONENT ${pkg_component}-dev
                    )
                endif()
            endif()
            
            # For some packages, try to install any license files
            if (DEFINED ${pkg_name}_SOURCE_DIR)
                file(GLOB license_files 
                    "${${pkg_name}_SOURCE_DIR}/LICENSE*" 
                    "${${pkg_name}_SOURCE_DIR}/COPYING*"
                )
                if (license_files)
                    install(FILES ${license_files}
                        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/licenses/${pkg_name}
                        COMPONENT ${pkg_component}-doc
                    )
                endif()
            endif()
        endif()
    endif()
endfunction()