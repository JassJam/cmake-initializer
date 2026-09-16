#
# loads dependencies for the HelloPackages
# adds:
#   - spdlog:
#     used for logging
#
function(HelloPackages_load_dependencies)
    if(COMMAND CPMAddPackage)
        cpmaddpackage(
            NAME
            spdlog
            URL
            https://github.com/gabime/spdlog/archive/refs/tags/v1.15.2.zip
            URL_HASH
            SHA256=d91ab0e16964cedb826e65ba1bed5ed4851d15c7b9453609a52056a94068c020
            OPTIONS
            "SPDLOG_BUILD_SHARED OFF"
            "SPDLOG_FMT_EXTERNAL OFF"
            "SPDLOG_NO_THREAD_ID ON"
            SYSTEM
            ON)

        target_link_dependencies(HelloPackages PRIVATE spdlog::spdlog)
    elseif(COMMAND xrepo_package)
        xrepo_package("spdlog" CONFIGS "std_format=true")

        xrepo_target_packages(HelloPackages spdlog)
    elseif(COMMAND spm_require_package)
        spm_require_package(NAME spdlog VERSION v1.17.0)

        target_link_dependencies(HelloPackages PRIVATE spdlog::spdlog)
    else()
        message(FATAL_ERROR "Unknown package specified")
    endif()

    # MSVC requires UTF-8 flag for spdlog Unicode support
    if(MSVC)
        target_compile_options(HelloPackages PRIVATE /utf-8)
    endif()
endfunction()
hellopackages_load_dependencies()
