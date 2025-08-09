#
# Static analysis tools setup (clang-tidy, cppcheck)
# Usage:
#   enable_global_static_analysis()                  # Enable static analysis globally
#   target_enable_static_analysis(target_name [ENABLE_CLANG_TIDY] [ENABLE_CPPCHECK])

# Global static analysis configuration
# Usage: enable_global_static_analysis(
#   [ENABLE_CLANG_TIDY]
#   [ENABLE_CPPCHECK] 
#   [ENABLE_EXCEPTIONS]
# )
function(enable_global_static_analysis)
    set(optionsArgs 
        ENABLE_CLANG_TIDY
        ENABLE_CPPCHECK
        ENABLE_EXCEPTIONS
    )
    cmake_parse_arguments(ARG "${options}" "" "" ${ARGN})

    if(ARG_ENABLE_CLANG_TIDY)
        set(CMAKE_CXX_CLANG_TIDY clang-tidy PARENT_SCOPE)

        if(ARG_ENABLE_EXCEPTIONS)
            set(CMAKE_CXX_CLANG_TIDY_EXCEPTIONS "--extra-arg=/EHsc" PARENT_SCOPE)
        else()
            set(CMAKE_CXX_CLANG_TIDY_EXCEPTIONS "--extra-arg=/EHs-c-" PARENT_SCOPE)
        endif()

        set(CMAKE_CXX_CLANG_TIDY_ARGS "--config-file=${CMAKE_SOURCE_DIR}/.clang-tidy" PARENT_SCOPE)
        set(CMAKE_CXX_CLANG_TIDY_HEADER_FILTER "^${CMAKE_SOURCE_DIR}/(?!out/build/.*/_deps/).*" PARENT_SCOPE)
        set(CMAKE_CXX_CLANG_TIDY_USE_COLOR "--use-color" PARENT_SCOPE)
        set(CMAKE_CXX_CLANG_TIDY_EXTRA_ARGS "--extra-arg=-Wno-unused-command-line-argument" PARENT_SCOPE)
        set(CMAKE_CXX_CLANG_TIDY_EXTRA_ARGS "${CMAKE_CXX_CLANG_TIDY_EXTRA_ARGS} --extra-arg=-Wno-unknown-argument" PARENT_SCOPE)

        if(WIN32)
            set(CMAKE_CXX_CLANG_TIDY_EXTRA_ARGS "${CMAKE_CXX_CLANG_TIDY_EXTRA_ARGS} --extra-arg=-Wno-dll-attribute-on-redeclaration" PARENT_SCOPE)
            set(CMAKE_CXX_CLANG_TIDY_EXTRA_ARGS "${CMAKE_CXX_CLANG_TIDY_EXTRA_ARGS} --extra-arg=-Wno-inconsistent-dllimport" PARENT_SCOPE)
            endif()
        if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
            if(ARG_ENABLE_EXCEPTIONS)
                set(CMAKE_CXX_CLANG_TIDY_EXTRA_ARGS "${CMAKE_CXX_CLANG_TIDY_EXTRA_ARGS} --extra-arg=/EHsc" PARENT_SCOPE)
            else()
                set(CMAKE_CXX_CLANG_TIDY_EXTRA_ARGS "${CMAKE_CXX_CLANG_TIDY_EXTRA_ARGS} --extra-arg=/EHs-c-" PARENT_SCOPE)
            endif()
        elseif(CMAKE_CXX_COMPILER_ID MATCHES "CLANG.*|GCC|EMSCRIPTEN")
            if(ARG_ENABLE_EXCEPTIONS)
                set(CMAKE_CXX_CLANG_TIDY_EXTRA_ARGS "${CMAKE_CXX_CLANG_TIDY_EXTRA_ARGS} --extra-arg=-fexceptions" PARENT_SCOPE)
            else()
                set(CMAKE_CXX_CLANG_TIDY_EXTRA_ARGS "${CMAKE_CXX_CLANG_TIDY_EXTRA_ARGS} --extra-arg=-fno-exceptions" PARENT_SCOPE)
            endif()
        endif()

        message(STATUS "** Global clang-tidy enabled")
    endif()
    
    if(ENABLE_CPPCHECK)
        find_program(CPPCHECK_EXE NAMES cppcheck)
        if(CPPCHECK_EXE)
            set(CMAKE_CXX_CPPCHECK ${CPPCHECK_EXE} PARENT_SCOPE)
            message(STATUS "** Global cppcheck enabled")
        else()
            message(WARNING "** cppcheck requested but not found")
        endif()
    endif()
endfunction()

#
# Enable static analysis for a specific target
# Usage: target_enable_static_analysis(target_name
#   [ENABLE_CLANG_TIDY]
#   [ENABLE_CPPCHECK]
#   [ENABLE_EXCEPTIONS]
# )
function(target_enable_static_analysis TARGET_NAME)
    set(options 
        ENABLE_CLANG_TIDY
        ENABLE_CPPCHECK
        ENABLE_EXCEPTIONS
    )
    cmake_parse_arguments(ARG "${options}" "" "" ${ARGN})
    
    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "target_enable_static_analysis: Target '${TARGET_NAME}' does not exist")
    endif()

    # clang-tidy setup
    if(ARG_ENABLE_CLANG_TIDY)
        _configure_clang_tidy(${TARGET_NAME} ${ARG_ENABLE_EXCEPTIONS})
    endif()

    # cppcheck setup
    if(ARG_ENABLE_CPPCHECK)
        _configure_cppcheck(${TARGET_NAME})
    endif()
endfunction()

#

# Helper function to create clang-tidy custom targets
function(_configure_clang_tidy TARGET_NAME ENABLE_EXCEPTIONS)
    find_program(CLANG_TIDY_EXE NAMES "clang-tidy")
        
    # If not found in PATH, try to find it using vswhere (Windows/Visual Studio)
    if(NOT CLANG_TIDY_EXE AND WIN32)
        find_program(VSWHERE_EXE NAMES "vswhere" 
            PATHS "$ENV{ProgramFiles\(x86\)}/Microsoft Visual Studio/Installer"
                  "$ENV{ProgramFiles}/Microsoft Visual Studio/Installer")
        
        if(VSWHERE_EXE)
            # First try to find VS with LLVM component specifically
            execute_process(
                COMMAND "${VSWHERE_EXE}" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Llvm.Clang -property installationPath
                OUTPUT_VARIABLE VS_INSTALLATION_PATH
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET
            )
            
            # If that fails, try with any VS installation that has VC tools
            if(NOT VS_INSTALLATION_PATH)
                execute_process(
                    COMMAND "${VSWHERE_EXE}" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
                    OUTPUT_VARIABLE VS_INSTALLATION_PATH
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    ERROR_QUIET
                )
            endif()
            
            # If still not found, try any VS installation (including Preview)
            if(NOT VS_INSTALLATION_PATH)
                execute_process(
                    COMMAND "${VSWHERE_EXE}" -all -products * -property installationPath
                    OUTPUT_VARIABLE VS_INSTALLATION_PATHS
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    ERROR_QUIET
                )
                # Take the first line (latest installation)
                string(REGEX REPLACE "\n.*" "" VS_INSTALLATION_PATH "${VS_INSTALLATION_PATHS}")
            endif()
            
            if(VS_INSTALLATION_PATH)
                # Try to find clang-tidy in LLVM tools
                find_program(CLANG_TIDY_EXE NAMES "clang-tidy"
                    PATHS "${VS_INSTALLATION_PATH}/VC/Tools/Llvm/x64/bin"
                          "${VS_INSTALLATION_PATH}/VC/Tools/Llvm/bin"
                    NO_DEFAULT_PATH
                )
                
                if(CLANG_TIDY_EXE)
                    message(STATUS "** clang-tidy found via vswhere: ${CLANG_TIDY_EXE}")
                else()
                    # If clang-tidy not found, check if we can enable MSVC static analysis
                    if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
                        message(STATUS "** clang-tidy not found, but MSVC compiler detected")
                        message(STATUS "** Consider using MSVC's built-in /analyze flag or installing LLVM tools")
                        # Set a flag to indicate MSVC static analysis could be used instead
                        set(MSVC_STATIC_ANALYSIS_AVAILABLE TRUE PARENT_SCOPE)
                    endif()
                endif()
            endif()
        endif()
    endif()
    
    if(CLANG_TIDY_EXE)
        message(STATUS "** clang-tidy found: ${CLANG_TIDY_EXE}")
        _add_clang_tidy_custom_target(${TARGET_NAME} ${ENABLE_EXCEPTIONS} ${CLANG_TIDY_EXE})
    else()
        message(WARNING "clang-tidy requested but not found")
        message(STATUS "** Consider installing LLVM tools with clang-tidy")
        message(STATUS "** Alternative: MSVC has built-in static analysis with /analyze flag")
    endif()
endfunction()

# Helper function to create clang-tidy custom targets
function(_add_clang_tidy_custom_target TARGET_NAME ENABLE_EXCEPTIONS CLANG_TIDY_EXE)
    if(NOT CLANG_TIDY_EXE)
        return()
    endif()
    
    # Build clang-tidy arguments
    set(CXX_CLANG_TIDY_ARGS "${CLANG_TIDY_EXE}")
    list(APPEND CXX_CLANG_TIDY_ARGS "--config-file=${CMAKE_SOURCE_DIR}/.clang-tidy")
    
    # Create .clang-tidy file for generated files directory to disable all checks
    get_target_property(TARGET_BINARY_DIR ${TARGET_NAME} BINARY_DIR)
    if(TARGET_BINARY_DIR)
        set(CLANG_TIDY_DISABLE_CONTENT "# Auto-generated .clang-tidy for generated files\n# Disable all clang-tidy checks\nChecks: '-*'\n")
        file(WRITE "${TARGET_BINARY_DIR}/.clang-tidy" "${CLANG_TIDY_DISABLE_CONTENT}")
    endif()
    
    if(WIN32)
        list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-Wno-dll-attribute-on-redeclaration")
        list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-Wno-inconsistent-dllimport")
    endif()

    get_current_compiler(CURRENT_COMPILER)
    list(APPEND CXX_CLANG_TIDY_ARGS "--use-color")
    
    if(CURRENT_COMPILER MATCHES "MSVC")
        if(${ENABLE_EXCEPTIONS})
            list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=/EHsc")
        else()
            list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=/EHs-c-")
        endif()
    elseif(CURRENT_COMPILER MATCHES "CLANG.*|GCC|EMSCRIPTEN")
        if(${ENABLE_EXCEPTIONS})
            list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-fexceptions")
        else()
            list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-fno-exceptions")
        endif()
        
        list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-Wno-unused-command-line-argument")
        list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-Wno-unknown-argument")
        
        # When using GCC compiler, ignore GCC-specific warning flags that clang-tidy doesn't understand
        if(CURRENT_COMPILER MATCHES "GCC")
            list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-Wno-error=unknown-warning-option")
            list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-Wno-duplicated-branches")
            list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-Wno-duplicated-cond")
            list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-Wno-logical-op")
            list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-Wno-useless-cast")
            # Tell clang-tidy to use GCC driver mode for compatibility
            list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg-before=--driver-mode=g++")
        endif()
    endif()
    
    set_target_properties(${TARGET_NAME} PROPERTIES
        CXX_CLANG_TIDY "${CXX_CLANG_TIDY_ARGS}"
    )

    if(MSVC)
        set_property(TARGET ${TARGET_NAME} PROPERTY VS_GLOBAL_EnableMicrosoftCodeAnalysis false)
        set_property(TARGET ${TARGET_NAME} PROPERTY VS_GLOBAL_EnableClangTidyCodeAnalysis true)
        set_property(TARGET ${TARGET_NAME} PROPERTY VS_GLOBAL_RunCodeAnalysis true)
    endif()
endfunction()

#

# Helper function to configure cppcheck for a target
function(_configure_cppcheck TARGET_NAME)
    find_program(CPPCHECK_EXE NAMES "cppcheck")
    if(CPPCHECK_EXE)
        message(STATUS "** cppcheck found: ${CPPCHECK_EXE}")
        set(CXX_CPPCHECK_ARGS "${CPPCHECK_EXE}")
        list(APPEND CXX_CPPCHECK_ARGS "--enable=warning,performance,portability,information,missingInclude")
        list(APPEND CXX_CPPCHECK_ARGS "--std=c++${CMAKE_CXX_STANDARD}")
        list(APPEND CXX_CPPCHECK_ARGS "--template=gcc")
        list(APPEND CXX_CPPCHECK_ARGS "--verbose")
        list(APPEND CXX_CPPCHECK_ARGS "--quiet")
        list(APPEND CXX_CPPCHECK_ARGS "--error-exitcode=1")

        set_target_properties(${TARGET_NAME} PROPERTIES
            CXX_CPPCHECK "${CXX_CPPCHECK_ARGS}"
        )
        message(STATUS "** cppcheck enabled for target: ${TARGET_NAME}")
    else()
        message(WARNING "cppcheck requested but not found")
    endif()
endfunction()
