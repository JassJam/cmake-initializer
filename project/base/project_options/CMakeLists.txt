add_library(${THIS_PROJECT_NAME}_options INTERFACE)
add_library(${THIS_PROJECT_NAMESPACE}::options ALIAS ${THIS_PROJECT_NAME}_options)

#

include(TargetAddCompilerWarnings)
include(TargetHardening)
include(TargetSanitizers)
include(StaticAnalysis)
include(StaticLinking)
include(ProjectOptions.cmake)

# enable IPO optimization if needed
if (ENABLE_IPO)
	include(EnableInterproceduralOptimization)
endif()

#

# set compiler warning flags
targets_add_compiler_warnings(
    TARGETS ${THIS_PROJECT_NAME}_options
    WARNINGS_AS_ERRORS ${ENABLE_WARNINGS_AS_ERRORS}
)

#

# enable sanitizers if needed
targets_enable_sanitizers(
    TARGETS ${THIS_PROJECT_NAME}_options
    ENABLE_SANITIZER_ADDRESS ${ENABLE_ASAN}
    ENABLE_SANITIZER_LEAK ${ENABLE_LSAN}
    ENABLE_SANITIZER_UNDEFINED_BEHAVIOR ${ENABLE_UBSAN}
    ENABLE_SANITIZER_THREAD ${ENABLE_TSAN}
    ENABLE_SANITIZER_MEMORY ${ENABLE_MSAN}
)

#

# enable static linking if needed
if (ENABLE_STATIC_RUNTIME)
    targets_enable_static_linking(
        TARGETS ${THIS_PROJECT_NAME}_options
    )
endif()

# enable unity build if needed
set_target_properties(
    ${THIS_PROJECT_NAME}_options
    PROPERTIES
    UNITY_BUILD ${ENABLE_UNITY_BUILD}
)

#

# enable project hardening if needed
if (ENABLE_HARDENING)
	targets_enable_hardening(
	    TARGETS ${THIS_PROJECT_NAME}_options
    )
endif()

# enable static analysis if needed
if (ENABLE_CLANG_TIDY OR ENABLE_CPPCHECK)
    enable_static_analysis(TARGETS ${THIS_PROJECT_NAME}_options)
endif()

# set PCH headers if needed
if (ENABLE_PCH)
    target_precompile_headers(
        ${THIS_PROJECT_NAME}_options
        INTERFACE
        <vector>
        <string>
        <utility>
        <algorithm>
    )
endif()

# install the component
install_component(
    ${THIS_PROJECT_NAME}_options
    INCLUDE_SUBDIR ${THIS_PROJECT_NAME}_options
)