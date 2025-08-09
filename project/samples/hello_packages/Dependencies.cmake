#
# loads dependencies for the target
# adds:
#   - spdlog:
#     used for logging
#
function(target_load_dependencies TARGET_NAME)
	if(COMMAND CPMAddPackage)
		CPMAddPackage(
			NAME spdlog
			URL https://github.com/gabime/spdlog/archive/refs/tags/v1.15.2.zip
			URL_HASH SHA256=d91ab0e16964cedb826e65ba1bed5ed4851d15c7b9453609a52056a94068c020
			OPTIONS "SPDLOG_BUILD_SHARED OFF" "SPDLOG_FMT_EXTERNAL OFF" "SPDLOG_NO_THREAD_ID ON"
			SYSTEM ON
		)
		
		target_link_dependencies(${TARGET_NAME}
			PRIVATE
				spdlog::spdlog
		)
	elseif(COMMAND xrepo_package)
		xrepo_package("spdlog" 
			CONFIGS "std_format=true")
		xrepo_target_packages(${TARGET_NAME} spdlog)
	else()
		message(FATAL_ERROR 
			"CPMAddPackage command not available. "
			"Ensure that CPM package manager is enabled by setting PACKAGE_MANAGER to include 'CPM' "
			"(e.g., PACKAGE_MANAGER=\"CPM\" or PACKAGE_MANAGER=\"CPM;XMake\")")
	endif()
	
	# MSVC requires UTF-8 flag for spdlog Unicode support
	if(MSVC)
		target_compile_options(${TARGET_NAME} PRIVATE /utf-8)
	endif()
endfunction()