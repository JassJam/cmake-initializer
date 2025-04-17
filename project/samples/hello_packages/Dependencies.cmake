#
# loads dependencies for the target
# adds:
#   - spdlog:
#     used for logging
#
function(target_load_dependencies target)
	target_add_dependency(${target}
		PACKAGES
			spdlog
				URL			https://github.com/gabime/spdlog/archive/refs/tags/v1.15.2.zip
				URL_HASH	SHA256=d91ab0e16964cedb826e65ba1bed5ed4851d15c7b9453609a52056a94068c020
				OPTIONS		"SPDLOG_BUILD_SHARED ON" 
	)
endfunction()