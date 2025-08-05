#
# loads dependencies for the target
# adds:
#   - spdlog:
#     used for logging
#
function(target_load_dependencies TARGET_NAME)
	CPMAddPackage(
		NAME		spdlog
		URL			https://github.com/gabime/spdlog/archive/refs/tags/v1.15.2.zip
		URL_HASH	SHA256=d91ab0e16964cedb826e65ba1bed5ed4851d15c7b9453609a52056a94068c020
		OPTIONS		"SPDLOG_BUILD_SHARED OFF" "SPDLOG_FMT_EXTERNAL OFF" "SPDLOG_NO_THREAD_ID ON"
		SYSTEM		ON
	)

	target_link_dependencies_auto(${TARGET_NAME}
		PRIVATE
			spdlog::spdlog
	)
endfunction()