add_library(${THIS_PROJECT_NAME}_options INTERFACE)
add_library(${THIS_PROJECT_NAMESPACE}::options ALIAS ${THIS_PROJECT_NAME}_options)

#

include(TargetAddCompilerWarnings)
include(TargetHardening)
include(TargetSanitizers)
include(ProjectOptions.cmake)

# enable IPO optimization if needed
if (PROJECT_ENABLE_IPO)
	include(EnableInterproceduralOptimization)
endif()

#

# set compiler warning flags
targets_add_compiler_warnings(
    TARGETS ${THIS_PROJECT_NAME}_options
    WARNINGS_AS_ERRORS ${PROJECT_WARNINGS_AS_ERRORS}
)

#

# enable sanitizers if needed
targets_enable_sanitizers(
    TARGETS ${THIS_PROJECT_NAME}_options
    ENABLE_SANITIZER_ADDRESS ${PROJECT_ENABLE_SANITIZER_ADDRESS}
    ENABLE_SANITIZER_LEAK ${PROJECT_ENABLE_SANITIZER_LEAK}
    ENABLE_SANITIZER_UNDEFINED_BEHAVIOR ${PROJECT_ENABLE_SANITIZER_UNDEFINED_BEHAVIOR}
    ENABLE_SANITIZER_THREAD ${PROJECT_ENABLE_SANITIZER_THREAD}
    ENABLE_SANITIZER_MEMORY ${PROJECT_ENABLE_SANITIZER_MEMORY}
)

#

# enable unity build if needed
set_target_properties(
    ${THIS_PROJECT_NAME}_options
    PROPERTIES
    UNITY_BUILD ${PROJECT_ENABLE_UNITY_BUILD}
)

#

# enable project hardening if needed
if (PROJECT_ENABLE_HARDENING OR PROJECT_ENABLE_GLOBAL_HARDENING)
	targets_enable_hardering(
	    TARGETS ${THIS_PROJECT_NAME}_options
    )
endif()

# set PCH headers if needed
if (PROJECT_ENABLE_PCH)
    target_precompile_headers(
        ${THIS_PROJECT_NAME}_options
        INTERFACE
        <vector>
        <string>
        <utility>
    )
endif()

# install the component
install_component(
    ${THIS_PROJECT_NAME}_options
    INCLUDE_SUBDIR ${THIS_PROJECT_NAME}_options
)