# ==============================================================================
# Common Project Options Setup
# ==============================================================================
# This function applies all common project options (warnings, sanitizers, 
# static analysis, hardening, etc.) directly to targets, replacing the need
# for a separate project_options interface library.

include_guard(GLOBAL)

include(CompilerWarnings)
include(TargetHardening)
include(TargetSanitizers)
include(StaticAnalysis)
include(StaticLinking)

# Apply common project options to a target
# Usage:
# setup_common_project_options(MyTarget)
function(setup_common_project_options TARGET_NAME)
    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "Target ${TARGET_NAME} does not exist")
    endif()

    # Enable IPO optimization if needed
    if(ENABLE_IPO)
        include(EnableInterproceduralOptimization)
        enable_interprocedural_optimization(TARGETS ${TARGET_NAME})
    endif()

    # Set compiler warning flags
    target_add_compiler_warnings(
        ${TARGET_NAME} PRIVATE
        WARNINGS_AS_ERRORS ${ENABLE_WARNINGS_AS_ERRORS}
    )

    # Configure exception handling
    target_configure_exceptions(
        ${TARGET_NAME} PRIVATE
        USE_EXCEPTIONS ${ENABLE_EXCEPTIONS}
    )

    # Enable sanitizers if needed
    targets_enable_sanitizers(
        TARGETS ${TARGET_NAME}
        ENABLE_SANITIZER_ADDRESS ${ENABLE_ASAN}
        ENABLE_SANITIZER_LEAK ${ENABLE_LSAN}
        ENABLE_SANITIZER_UNDEFINED_BEHAVIOR ${ENABLE_UBSAN}
        ENABLE_SANITIZER_THREAD ${ENABLE_TSAN}
        ENABLE_SANITIZER_MEMORY ${ENABLE_MSAN}
    )

    # Enable static linking if needed
    if(ENABLE_STATIC_RUNTIME)
        targets_enable_static_linking(
            TARGETS ${TARGET_NAME}
        )
    endif()

    # Enable unity build if needed
    set_target_properties(
        ${TARGET_NAME}
        PROPERTIES
        UNITY_BUILD ${ENABLE_UNITY_BUILD}
    )

    # Enable project hardening if needed
    if(ENABLE_HARDENING)
        targets_enable_hardening(
            TARGETS ${TARGET_NAME}
        )
    endif()

    # Enable static analysis if needed
    if(ENABLE_CLANG_TIDY OR ENABLE_CPPCHECK)
        target_enable_static_analysis(${TARGET_NAME})
    endif()

    # Set PCH headers if needed
    if(ENABLE_PCH)
        target_precompile_headers(
            ${TARGET_NAME}
            PRIVATE
            <vector>
            <string>
            <utility>
            <algorithm>
        )
    endif()
endfunction()
