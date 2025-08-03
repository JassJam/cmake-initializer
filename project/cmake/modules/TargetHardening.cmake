include_guard(GLOBAL)

include(GetCurrentCompiler)

#
# Enable hardening flags for the project globally to all targets and dependencies
#
# Example usage:
# enable_global_hardening()
#
function(enable_global_hardening)
	# Call once
	get_property(already_registered GLOBAL PROPERTY PROJECT_GLOBAL_HARDENING_ENABLED)
	if(already_registered)
        return()
    endif()

	message(STATUS "** Enable global hardening to all targets and all dependencies")

    _get_hardening_options(NEW_COMPILE_OPTIONS NEW_LINK_OPTIONS NEW_CXX_DEFINITIONS)
    
    message(STATUS "** Hardening Compiler Flags: ${NEW_COMPILE_OPTIONS}")
    message(STATUS "** Hardening Linker Flags: ${NEW_LINK_OPTIONS}")
    message(STATUS "** Hardening Compiler Defines: ${NEW_CXX_DEFINITIONS}")
    
    message(STATUS "** Setting hardening options globally for all dependencies")
    
    # Set global compile options - use add_compile_options instead of modifying CMAKE_CXX_FLAGS
    if(NOT "${NEW_COMPILE_OPTIONS}" STREQUAL "")
        add_compile_options(${NEW_COMPILE_OPTIONS})
    endif()
    
    # Set global link options - use add_link_options instead of modifying CMAKE_*_LINKER_FLAGS
    if(NOT "${NEW_LINK_OPTIONS}" STREQUAL "")
        add_link_options(${NEW_LINK_OPTIONS})
    endif()
    
    # Set global compile definitions
    if(NOT "${NEW_CXX_DEFINITIONS}" STREQUAL "")
        foreach(DEFINITION ${NEW_CXX_DEFINITIONS})
            add_compile_definitions(${DEFINITION})
        endforeach()
    endif()

    set_property(GLOBAL PROPERTY PROJECT_GLOBAL_HARDENING_ENABLED TRUE)
endfunction()

#
# Enable hardening for a specific target
# Usage:
# target_enable_hardening(MyTarget)
function(target_enable_hardening TARGET_NAME)
    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "Target ${TARGET_NAME} does not exist")
    endif()

    _get_hardening_options(NEW_COMPILE_OPTIONS NEW_LINK_OPTIONS NEW_CXX_DEFINITIONS)
    
    message(STATUS "** Hardening Compiler Flags: ${NEW_COMPILE_OPTIONS}")
    message(STATUS "** Hardening Linker Flags: ${NEW_LINK_OPTIONS}")
    message(STATUS "** Hardening Compiler Defines: ${NEW_CXX_DEFINITIONS}")
    
    # Set target-specific compile options
    if(NOT "${NEW_COMPILE_OPTIONS}" STREQUAL "")
        target_compile_options(${TARGET_NAME} PRIVATE ${NEW_COMPILE_OPTIONS})
    endif()
    
    # Set target-specific link options
    if(NOT "${NEW_LINK_OPTIONS}" STREQUAL "")
        target_link_options(${TARGET_NAME} PRIVATE ${NEW_LINK_OPTIONS})
    endif()
    
    # Set target-specific compile definitions
    if(NOT "${NEW_CXX_DEFINITIONS}" STREQUAL "")
        target_compile_definitions(${TARGET_NAME} PRIVATE ${NEW_CXX_DEFINITIONS})
    endif()

    message(STATUS "** Enable hardening for targets: ${TARGET_NAME}")
endfunction()

#

#
# Private function to determine if UBSan minimal runtime should be enabled
#
function(_should_enable_ubsan_minimal_runtime RESULT_VAR)
    if(NOT SUPPORTS_UBSAN 
         OR PROJECT_ENABLE_SANITIZER_UNDEFINED
         OR PROJECT_ENABLE_SANITIZER_ADDRESS
         OR PROJECT_ENABLE_SANITIZER_THREAD
         OR PROJECT_ENABLE_SANITIZER_LEAK)
        set(${RESULT_VAR} FALSE PARENT_SCOPE)
    else()
        set(${RESULT_VAR} TRUE PARENT_SCOPE)
    endif()
endfunction()

#
# Private function to configure MSVC hardening flags
#
function(_configure_msvc_hardening COMPILE_OPTIONS_VAR LINK_OPTIONS_VAR DEFINITIONS_VAR)
    # Check if Edit and Continue is enabled globally (for compatibility)
    if(ENABLE_EDIT_AND_CONTINUE)
        message(STATUS "*** Hardening MSVC flags: /DYNAMICBASE /NXCOMPAT /CETCOMPAT (Control Flow Guard disabled due to Edit and Continue)")
        # Skip /guard:cf when Edit and Continue is enabled
    else()
        message(STATUS "*** Hardening MSVC flags: /DYNAMICBASE /guard:cf /NXCOMPAT /CETCOMPAT")
        # /guard:cf is a compiler flag for Control Flow Guard
        list(APPEND ${COMPILE_OPTIONS_VAR} /guard:cf)
    endif()
    
    # /DYNAMICBASE, /NXCOMPAT, /CETCOMPAT are linker flags
    list(APPEND ${LINK_OPTIONS_VAR} /DYNAMICBASE /NXCOMPAT /CETCOMPAT)
    
    set(${COMPILE_OPTIONS_VAR} ${${COMPILE_OPTIONS_VAR}} PARENT_SCOPE)
    set(${LINK_OPTIONS_VAR} ${${LINK_OPTIONS_VAR}} PARENT_SCOPE)
endfunction()

#
# Private function to configure GCC/Clang hardening flags
#
function(_configure_gcc_clang_hardening COMPILE_OPTIONS_VAR LINK_OPTIONS_VAR DEFINITIONS_VAR CURRENT_COMPILER)
    message(STATUS "*** GLIBC++ Assertions (vector[], string[], ...) enabled")
    list(APPEND ${DEFINITIONS_VAR} -D_GLIBCXX_DEBUG -D_GLIBCXX_DEBUG_PEDANTIC -D_GLIBCXX_ASSERTIONS)

    message(STATUS "*** g++/clang _FORTIFY_SOURCE=3 enabled")
    list(APPEND ${COMPILE_OPTIONS_VAR} -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3)

    # Stack protector
    check_cxx_compiler_flag(-fstack-protector-strong STACK_PROTECTOR)
    if(STACK_PROTECTOR)
        message(STATUS "*** g++/clang -fstack-protector-strong enabled")
        list(APPEND ${COMPILE_OPTIONS_VAR} -fstack-protector-strong)
    else()
        message(STATUS "*** g++/clang -fstack-protector-strong NOT enabled (not supported)")
    endif()

    # Control flow protection
    check_cxx_compiler_flag(-fcf-protection CF_PROTECTION)
    if(CF_PROTECTION)
        message(STATUS "*** g++/clang -fcf-protection enabled")
        list(APPEND ${COMPILE_OPTIONS_VAR} -fcf-protection)
    else()
        message(STATUS "*** g++/clang -fcf-protection NOT enabled (not supported)")
    endif()

    # Stack clash protection
    check_cxx_compiler_flag(-fstack-clash-protection CLASH_PROTECTION)
    if(CLASH_PROTECTION)
        if(LINUX OR CURRENT_COMPILER MATCHES "GCC")
            message(STATUS "*** g++/clang -fstack-clash-protection enabled")
            list(APPEND ${COMPILE_OPTIONS_VAR} -fstack-clash-protection)
        else()
            message(STATUS "*** g++/clang -fstack-clash-protection NOT enabled (clang on non-Linux)")
        endif()
    else()
        message(STATUS "*** g++/clang -fstack-clash-protection NOT enabled (not supported)")
    endif()

    # UBSan minimal runtime
    _should_enable_ubsan_minimal_runtime(ENABLE_UBSAN_MINIMAL_RUNTIME)
    if(ENABLE_UBSAN_MINIMAL_RUNTIME)
        check_cxx_compiler_flag("-fsanitize=undefined -fno-sanitize-recover=undefined -fsanitize-minimal-runtime"
                            MINIMAL_RUNTIME)
        if(MINIMAL_RUNTIME)
            list(APPEND ${COMPILE_OPTIONS_VAR} -fsanitize=undefined -fsanitize-minimal-runtime -fno-sanitize-recover=undefined)
            list(APPEND ${LINK_OPTIONS_VAR} -fsanitize=undefined -fsanitize-minimal-runtime -fno-sanitize-recover=undefined)
            message(STATUS "*** ubsan minimal runtime enabled")
        else()
            message(STATUS "*** ubsan minimal runtime NOT enabled (not supported)")
        endif()
    endif()

    set(${COMPILE_OPTIONS_VAR} ${${COMPILE_OPTIONS_VAR}} PARENT_SCOPE)
    set(${LINK_OPTIONS_VAR} ${${LINK_OPTIONS_VAR}} PARENT_SCOPE)
    set(${DEFINITIONS_VAR} ${${DEFINITIONS_VAR}} PARENT_SCOPE)
endfunction()

#
# Private function to get hardening options for current compiler
#
function(_get_hardening_options COMPILE_OPTIONS_VAR LINK_OPTIONS_VAR DEFINITIONS_VAR)
    get_current_compiler(CURRENT_COMPILER)
    
    set(NEW_LINK_OPTIONS "")
    set(NEW_COMPILE_OPTIONS "")
    set(NEW_CXX_DEFINITIONS "")

    if(CURRENT_COMPILER STREQUAL "MSVC")
        _configure_msvc_hardening(NEW_COMPILE_OPTIONS NEW_LINK_OPTIONS NEW_CXX_DEFINITIONS)
    elseif(CURRENT_COMPILER MATCHES "CLANG.*|GCC")
        _configure_gcc_clang_hardening(NEW_COMPILE_OPTIONS NEW_LINK_OPTIONS NEW_CXX_DEFINITIONS CURRENT_COMPILER)
    else()
        message(STATUS "*** ubsan minimal runtime NOT enabled (not requested)")
    endif()
    
    set(${COMPILE_OPTIONS_VAR} ${NEW_COMPILE_OPTIONS} PARENT_SCOPE)
    set(${LINK_OPTIONS_VAR} ${NEW_LINK_OPTIONS} PARENT_SCOPE)
    set(${DEFINITIONS_VAR} ${NEW_CXX_DEFINITIONS} PARENT_SCOPE)
endfunction()