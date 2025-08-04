#
# Interprocedural Optimization (IPO/LTO) setup
# usage:
#   enable_global_interprocedural_optimization()     # Enable IPO globally
#   target_enable_interprocedural_optimization(target_name)  # Enable IPO for specific target
#

include(CheckIPOSupported)

# Global IPO configuration
function(enable_global_interprocedural_optimization)
    check_ipo_supported(RESULT result OUTPUT output)

    if(result)
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON PARENT_SCOPE)
        message(STATUS "** Global IPO enabled: ${output}")
    else()
        message(WARNING "** IPO is not supported: ${output}")
    endif()
endfunction()

# Target-specific IPO configuration
function(target_enable_interprocedural_optimization TARGET_NAME)
    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "target_enable_interprocedural_optimization: Target '${TARGET_NAME}' does not exist")
    endif()

    check_ipo_supported(RESULT result OUTPUT output)

    if(result)
        set_target_properties(${TARGET_NAME} PROPERTIES
            INTERPROCEDURAL_OPTIMIZATION TRUE
        )
        message(STATUS "** IPO enabled for target '${TARGET_NAME}': ${output}")
    else()
        message(WARNING "** IPO is not supported for target '${TARGET_NAME}': ${output}")
    endif()
endfunction()

# Legacy support - this maintains the old global behavior for backward compatibility
check_ipo_supported(RESULT result OUTPUT output)

if(result)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
    message(STATUS "** IPO is supported: ${output}")
else()
    message(SEND_ERROR "** IPO is not supported: ${output}")
endif()
