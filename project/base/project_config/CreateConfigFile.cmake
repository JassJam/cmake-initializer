# function used to create the config file of the project
# usage: 
#   _create_config_file(version)                               # Uses default: ${THIS_PROJECT_NAMESPACE}/config/config.hpp
#   _create_config_file(version CONFIG_DIR custom_dir)        # Uses custom generation directory
#   _create_config_file(version INSTALL_SUBDIR custom_subdir) # Uses custom install subdirectory
# 
# Parameters:
#   version - The project version string (e.g., "1.0.0")
#   CONFIG_DIR - Optional custom generation directory (full path including filename)
#   INSTALL_SUBDIR - Optional custom installation subdirectory under CMAKE_INSTALL_INCLUDEDIR
#
# Examples:
#   _create_config_file("1.0.0")                                      # → install/include/myproject/config/config.hpp  
#   _create_config_file("1.0.0" INSTALL_SUBDIR "mylib")               # → install/include/mylib/config.hpp
#   _create_config_file("1.0.0" CONFIG_DIR "/custom/path/config.hpp") # Custom generation path (advanced) to create the config file of the project
# usage: 
#   _create_config_file(version)                               # Uses default: ${THIS_PROJECT_NAMESPACE}/config.hpp
#   _create_config_file(version CONFIG_DIR custom_dir)        # Uses custom generation directory
#   _create_config_file(version INSTALL_SUBDIR custom_subdir) # Uses custom install subdirectory
# 
# Parameters:
#   version - The project version string (e.g., "1.0.0")
#   CONFIG_DIR - Optional custom generation directory (full path)
#   INSTALL_SUBDIR - Optional custom installation subdirectory under CMAKE_INSTALL_INCLUDEDIR
#
# Examples:
#   _create_config_file("1.0.0")                                      # → include/myproject/config.hpp  
#   _create_config_file("1.0.0" INSTALL_SUBDIR "mylib")               # → include/mylib/config.hpp
#   _create_config_file("1.0.0" CONFIG_DIR "/custom/path/config.hpp") # → /custom/path/config.hpp
function(_create_config_file version)
	set(options)
	set(oneValueArgs CONFIG_DIR INSTALL_SUBDIR)
	set(multiValueArgs)
	cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
	# using THIS_PROJECT_VERSION, it can be "" or "1" or "1.0" or "1.0.0"
	# split the version string into major, minor, patch and tweak
	string(REGEX MATCHALL "[0-9]+" version_parts ${version})
	
	# get the number of parts
	list(LENGTH version_parts version_parts_count)
	
	# if we have at least 1 part, set the major version
	if(version_parts_count GREATER 0)
		list(GET version_parts 0 PROJECT_VERSION_MAJOR)
	else()
		set(PROJECT_VERSION_MAJOR 0)
	endif()
	# if we have at least 2 parts, set the minor version
	if(version_parts_count GREATER 1)
		list(GET version_parts 1 PROJECT_VERSION_MINOR)
	else()
		set(PROJECT_VERSION_MINOR 0)
	endif()
	# if we have at least 3 parts, set the patch version
	if(version_parts_count GREATER 2)
		list(GET version_parts 2 PROJECT_VERSION_PATCH)
	else()
		set(PROJECT_VERSION_PATCH 0)
	endif()
	
	# Get git commit hash if available
	if(NOT DEFINED GIT_SHA)
		find_package(Git QUIET)
		if(Git_FOUND)
			execute_process(
				COMMAND ${GIT_EXECUTABLE} rev-parse HEAD
				WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
				OUTPUT_VARIABLE GIT_SHA
				OUTPUT_STRIP_TRAILING_WHITESPACE
				ERROR_QUIET
			)
			if(NOT GIT_SHA)
				set(GIT_SHA "Unknown")
			endif()
		else()
			set(GIT_SHA "Unknown")
		endif()
	endif()

	# configure the file commonly used in the project
	if(ARG_CONFIG_DIR)
		set(CONFIG_DIR ${ARG_CONFIG_DIR})
		message(STATUS "Using custom config generation directory: ${CONFIG_DIR}")
	else()
		set(CONFIG_DIR "${CMAKE_CURRENT_BINARY_DIR}/include/config/config.hpp")
	endif()
	
	# Determine installation subdirectory
	if(ARG_INSTALL_SUBDIR)
		set(INSTALL_SUBDIR "${ARG_INSTALL_SUBDIR}")
		message(STATUS "Using custom config install location: ${INSTALL_SUBDIR}/config.hpp")
	else()
		set(INSTALL_SUBDIR "${THIS_PROJECT_NAMESPACE}/config")
		message(STATUS "Using default config install location: ${INSTALL_SUBDIR}/config.hpp")
	endif()
	
	# create the directory if it does not exist
	get_filename_component(CONFIG_DIR_PARENT "${CONFIG_DIR}" DIRECTORY)
	file(MAKE_DIRECTORY "${CONFIG_DIR_PARENT}")
	configure_file("./_config/config.hpp.in" "${CONFIG_DIR}" @ONLY)

	# add include directories
	target_include_directories(${THIS_PROJECT_NAME}_config
		INTERFACE
			$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
			$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/${INSTALL_SUBDIR}>
	)

	# add the include directory to the 'config' library
	set_target_properties(${THIS_PROJECT_NAME}_config
		PROPERTIES
			PUBLIC_HEADER "${CONFIG_DIR}"
	)
	
	# Set the INSTALL_SUBDIR in parent scope so install_component can use it
	set(CONFIG_INSTALL_SUBDIR "${INSTALL_SUBDIR}" PARENT_SCOPE)
endfunction()
