include_guard(GLOBAL)

include(GetCurrentCompiler)

# ==============================================================================

#
# Enable exception for the current target
# usage:
#   target_configure_exceptions(TARGET_NAME [ON/OFF]
function(target_configure_exceptions TARGET_NAME ON_OFF)
    if(GLOBAL_EXCEPTIONS_SET)
        message(TRACE "Global exceptions are already enabled, ignoring target-specific settings")
        return()
    endif()

    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "Target ${TARGET_NAME} does not exist")
    endif()

    _configure_exceptions(OUTPUT_FLAGS ON_OFF)
    if(OUTPUT_FLAGS)
        target_compile_options(${TARGET_NAME} PRIVATE ${OUTPUT_FLAGS})
    endif()
endfunction()

#
# Enable global exceptions handling
#
# usage:
#   enable_global_exceptions([ON/OFF])
function(configure_global_exceptions ON_OFF)
    _configure_exceptions(OUTPUT_FLAGS ON_OFF)
    if(OUTPUT_FLAGS)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OUTPUT_FLAGS}")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OUTPUT_FLAGS}")
    endif()

    set(GLOBAL_EXCEPTIONS_SET TRUE PARENT_SCOPE)
    message(STATUS "Global exceptions enabled")
endfunction()

#

function(_configure_exceptions OUTPUT_FLAGS ON_OFF)
    get_current_compiler(CURRENT_COMPILER)
    if(CURRENT_COMPILER STREQUAL "MSVC" OR CURRENT_COMPILER STREQUAL "CLANG-MSVC")
        if(ON_OFF)
            set(OUTPUT_FLAGS "/EHsc" PARENT_SCOPE)
        else()
            set(OUTPUT_FLAGS "/EHs-c-" PARENT_SCOPE)
        endif()
    elseif(CURRENT_COMPILER MATCHES "CLANG.*|GCC|EMSCRIPTEN")
        if(ON_OFF)
            set(OUTPUT_FLAGS "-fexceptions" PARENT_SCOPE)
        else()
            set(OUTPUT_FLAGS "-fno-exceptions" PARENT_SCOPE)
        endif()
    else()
        message(WARNING "Unknown compiler ${CURRENT_COMPILER}, not applying exceptions settings")
    endif()
endfunction()
