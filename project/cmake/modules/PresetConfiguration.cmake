# ==============================================================================
# Preset-Based Configuration System
# ==============================================================================
# This module handles automatic configuration based on CMake preset variables
# including test framework registration and CTest dashboard setup.

# Auto-register test framework if DEFAULT_TEST_FRAMEWORK is defined in preset
function(configure_preset_test_framework)
    if(DEFINED DEFAULT_TEST_FRAMEWORK AND BUILD_TESTING)
        message(STATUS "Auto-registering test framework from preset: ${DEFAULT_TEST_FRAMEWORK}")
        
        # Verify the framework is supported
        set(SUPPORTED_FRAMEWORKS "doctest" "catch2" "gtest" "boost")
        if(NOT DEFAULT_TEST_FRAMEWORK IN_LIST SUPPORTED_FRAMEWORKS)
            message(FATAL_ERROR "Unsupported test framework '${DEFAULT_TEST_FRAMEWORK}' in preset. Supported: ${SUPPORTED_FRAMEWORKS}")
        endif()
        
        # Check if framework is already registered to avoid duplicates
        get_property(already_registered GLOBAL PROPERTY TEST_FRAMEWORK_REGISTERED)
        if(NOT already_registered)
            register_test_framework(${DEFAULT_TEST_FRAMEWORK})
        else()
            message(STATUS "Test framework already registered, skipping auto-registration")
        endif()
    endif()
endfunction()

# Configure CTest dashboard upload settings from preset variables
function(configure_preset_ctest_upload)
    # Modern CMake 3.14+ format
    if(DEFINED CTEST_SUBMIT_URL_PRESET)
        set(CTEST_SUBMIT_URL ${CTEST_SUBMIT_URL_PRESET} PARENT_SCOPE)
        message(STATUS "CTest upload configured via CTEST_SUBMIT_URL_PRESET: ${CTEST_SUBMIT_URL_PRESET}")
        
    # Legacy format with separate site and location
    elseif(DEFINED CTEST_DROP_SITE_PRESET AND DEFINED CTEST_DROP_LOCATION_PRESET)
        # Get HTTP protocol from preset or default to https
        if(DEFINED CTEST_DROP_METHOD)
            set(protocol ${CTEST_DROP_METHOD})
        else()
            set(protocol "https")
        endif()
        
        if(CMAKE_VERSION VERSION_GREATER 3.14)
            set(CTEST_SUBMIT_URL "${protocol}://${CTEST_DROP_SITE_PRESET}${CTEST_DROP_LOCATION_PRESET}" PARENT_SCOPE)
            message(STATUS "CTest upload configured: ${protocol}://${CTEST_DROP_SITE_PRESET}${CTEST_DROP_LOCATION_PRESET}")
        else()
            set(CTEST_DROP_METHOD ${protocol} PARENT_SCOPE)
            set(CTEST_DROP_SITE ${CTEST_DROP_SITE_PRESET} PARENT_SCOPE)
            set(CTEST_DROP_LOCATION ${CTEST_DROP_LOCATION_PRESET} PARENT_SCOPE)
            message(STATUS "CTest upload configured (legacy): ${protocol}://${CTEST_DROP_SITE_PRESET}${CTEST_DROP_LOCATION_PRESET}")
        endif()
        set(CTEST_DROP_SITE_CDASH TRUE PARENT_SCOPE)
        
    # Partial configuration warning
    elseif(DEFINED CTEST_DROP_SITE_PRESET OR DEFINED CTEST_DROP_LOCATION_PRESET)
        message(WARNING "Incomplete CTest configuration: Both CTEST_DROP_SITE_PRESET and CTEST_DROP_LOCATION_PRESET must be defined")
    endif()
endfunction()

# Configure preset-based build name for dashboard
function(configure_preset_build_name)
    if(DEFINED CTEST_BUILD_NAME_PRESET)
        set(CTEST_BUILD_NAME ${CTEST_BUILD_NAME_PRESET} PARENT_SCOPE)
        message(STATUS "CTest build name from preset: ${CTEST_BUILD_NAME_PRESET}")
    else()
        # Default build name
        set(CTEST_BUILD_NAME "${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}" PARENT_SCOPE)
    endif()
endfunction()

# Configure CTest timeout from preset variables
function(configure_preset_test_timeout)
    if(DEFINED CTEST_TEST_TIMEOUT_PRESET)
        set(CTEST_TEST_TIMEOUT ${CTEST_TEST_TIMEOUT_PRESET} PARENT_SCOPE)
        message(STATUS "CTest test timeout configured from preset: ${CTEST_TEST_TIMEOUT_PRESET} seconds")
    endif()
endfunction()

# Main preset configuration function - call this to apply all preset-based settings
function(configure_from_presets)
    message(STATUS "Configuring project from preset variables...")
    
    configure_preset_test_framework()
    configure_preset_ctest_upload()
    configure_preset_test_timeout()
    configure_preset_build_name()
    
    message(STATUS "Preset configuration completed")
endfunction()
