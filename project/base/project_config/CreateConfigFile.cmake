# function used to create the config file of the project
function(_create_config_file version)
	# using THIS_PROJECT_VERSION, it can be "" or "1" or "1.0" or "1.0.0"
	# split the version string into major, minor, patch and tweak
	string(REGEX MATCHALL "[0-9]+" version_parts ${version})
	
	# get the number of parts
	list(LENGTH version_parts version_parts_count)
	
	# if we have at least 1 part, set the major version
	if (version_parts_count GREATER 0)
		list(GET version_parts 0 PROJECT_VERSION_MAJOR)
	endif()
	# if we have at least 2 parts, set the minor version
	if (version_parts_count GREATER 1)
		list(GET version_parts 1 PROJECT_VERSION_MINOR)
	endif()
	# if we have at least 3 parts, set the patch version
	if (version_parts_count GREATER 2)
		list(GET version_parts 2 PROJECT_VERSION_PATCH)
	endif()
	
	# if GIT_SHA is not defined, set it to "Unknown"
	if (NOT DEFINED GIT_SHA)
		set(GIT_SHA "Unknown")
	endif()

	# configure the file commonly used in the project
	configure_file("./_config/config.hpp.in" "${CMAKE_CURRENT_BINARY_DIR}/include/config/config.hpp" @ONLY)

	# add include directories
	target_include_directories(${THIS_PROJECT_NAME}_config
		INTERFACE
			$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
			$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/${THIS_PROJECT_NAME}_config>
	)

	# add the include directory to the 'config' library
	set_target_properties(${THIS_PROJECT_NAME}_config
		PROPERTIES
			PUBLIC_HEADER "${CMAKE_CURRENT_BINARY_DIR}/include/config/config.hpp"
	)
endfunction()
