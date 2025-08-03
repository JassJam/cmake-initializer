#
# Static analysis tools setup (clang-tidy, cppcheck)
# Usage:
#   target_enable_static_analysis(target_name)
function(target_enable_static_analysis TARGET_NAME)
    if(NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "target_enable_static_analysis: Target '${TARGET_NAME}' does not exist")
    endif()

    # clang-tidy setup
    if(ENABLE_CLANG_TIDY)
        _configure_clang_tidy(${TARGET_NAME})
    endif()

    # cppcheck setup
    if(ENABLE_CPPCHECK)
        _configure_cppcheck(${TARGET_NAME})
    endif()
endfunction()

# 
# Function to enable static analysis for multiple targets
# Usage: targets_enable_static_analysis(target1 target2 ...)
function(targets_enable_static_analysis)
    foreach(TARGET_NAME ${ARGN})
        target_enable_static_analysis(${TARGET_NAME})
    endforeach()
endfunction()

#

# Helper function to create clang-tidy custom targets
function(_configure_clang_tidy TARGET_NAME)
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
        # For Visual Studio generator with MSVC, clang-tidy integration doesn't work during build
        # Provide alternative approaches based on compiler and generator
        if(CMAKE_GENERATOR MATCHES "Visual Studio" AND CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
            message(STATUS "** Visual Studio + MSVC: clang-tidy doesn't run during build")
            message(STATUS "** Option for ${TARGET_NAME}: Manual clang-tidy via cmake --build . --target ${TARGET_NAME}_clang_tidy")
            
            # Don't set the property as it doesn't work with MSVC + Visual Studio
            # Just create the custom target for manual execution
            _add_clang_tidy_custom_target(${TARGET_NAME} ${CLANG_TIDY_EXE} FALSE)
        elseif(CMAKE_GENERATOR MATCHES "Visual Studio")
            message(STATUS "** Visual Studio generator - clang-tidy via custom target for: ${TARGET_NAME}")
            # For Visual Studio with Clang compiler, try the property but primarily use custom targets
            _add_clang_tidy_custom_target(${TARGET_NAME} ${CLANG_TIDY_EXE} TRUE)
        else()
            # For other generators (Ninja, Unix Makefiles), the property works well
            _add_clang_tidy_custom_target(${TARGET_NAME} ${CLANG_TIDY_EXE} TRUE)
            message(STATUS "** clang-tidy enabled for target: ${TARGET_NAME}")
        endif()
    else()
        # If clang-tidy not found, inform user about alternatives
        if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
            message(WARNING "clang-tidy requested but not found")
            message(STATUS "** Consider installing LLVM tools with clang-tidy")
            message(STATUS "** Alternative: MSVC has built-in static analysis with /analyze flag")
        else()
            message(WARNING "clang-tidy requested but not found, and compiler is not MSVC")
            message(STATUS "** Consider installing clang-tidy or LLVM tools")
        endif()
    endif()
endfunction()

# Helper function to create clang-tidy custom targets
function(_add_clang_tidy_custom_target TARGET_NAME clang_tidy_exe set_target_property)
    if(NOT clang_tidy_exe)
        return()
    endif()
    
    # Build clang-tidy arguments
    set(CXX_CLANG_TIDY_ARGS "${clang_tidy_exe}")
    list(APPEND CXX_CLANG_TIDY_ARGS "--config-file=${CMAKE_SOURCE_DIR}/.clang-tidy")
    list(APPEND CXX_CLANG_TIDY_ARGS "--header-filter=^${CMAKE_SOURCE_DIR}/(?!out/build/.*/_deps/).*")
    
    if(WIN32)
        list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-Wno-dll-attribute-on-redeclaration")
        list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-Wno-inconsistent-dllimport")
    endif()

    get_current_compiler(CURRENT_COMPILER)
    list(APPEND CXX_CLANG_TIDY_ARGS "--use-color")
    
    if(CURRENT_COMPILER MATCHES "MSVC")
        if(ENABLE_EXCEPTIONS)
            list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=/EHsc")
        else()
            list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=/EHsc-")
        endif()
    elseif(CURRENT_COMPILER MATCHES "CLANG.*|GCC|EMSCRIPTEN")
        if(ENABLE_EXCEPTIONS)
            list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-fexceptions")
        else()
            list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-fno-exceptions")
        endif()
        
        list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-Wno-unused-command-line-argument")
        list(APPEND CXX_CLANG_TIDY_ARGS "--extra-arg=-Wno-unknown-argument")
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

        if(ENABLE_WARNINGS_AS_ERRORS)
            list(APPEND CPPCHECK_ARGS "--error-exitcode=1")
        endif()

        set_target_properties(${TARGET_NAME} PROPERTIES
            CXX_CPPCHECK "${CXX_CPPCHECK_ARGS}"
        )
        message(STATUS "** cppcheck enabled for target: ${TARGET_NAME}")
    else()
        message(WARNING "cppcheck requested but not found")
    endif()
endfunction()
