include_guard(GLOBAL)

cmake_minimum_required(VERSION 3.21)

set(XC_VERBOSE_OUTPUT ON CACHE BOOL "Enable verbose output for Xrepo Packages")
set(XC_BOOTSTRAP_XMAKE ON CACHE BOOL "Bootstrap Xmake automatically")
set(XC_XMAKE_VERSION "3.0.3" CACHE STRING "XMake version")

#

set(XMAKE_CMD "")
set(XREPO_TOOLCHAIN "")

#
# xrepo_require(
#   NAME
#   [ALIAS <name>]
#   [VERSION 1.2.3]
#   [CONFIGS option1=true;option2=false]
#   [DEBUG]
#   [IMPORTS <path>...]
# )
#

function(_xcmake_log)
    if(XC_VERBOSE_OUTPUT)
        string(REPLACE "\\" "\\\\" _msg "${ARGV}")
        message(STATUS "[XCMake]: ${_msg}.")
    endif()
endfunction()

function(_xcmake_fatal)
    string(REPLACE "\\" "\\\\" _spm_log_fatal_msg "${ARGV}")
    message(FATAL_ERROR "[XCMake]: ${_spm_log_fatal_msg}.")
endfunction()

macro(_xcmake_execute_process)
    _xcmake_log("Executing ${ARGV}")
    execute_process(${ARGV})
endmacro()

#

function(_detect_toolchain)
    if(DEFINED CMAKE_C_COMPILER)
        get_filename_component(_compiler_name "${CMAKE_C_COMPILER}" NAME_WLE)
    elseif(DEFINED CMAKE_CXX_COMPILER)
        get_filename_component(_compiler_name "${CMAKE_CXX_COMPILER}" NAME_WLE)
        string(REPLACE "g++" "gcc" _compiler_name "${_compiler_name}")
        string(REPLACE "clang++" "clang" _compiler_name "${_compiler_name}")
    else()
        return()
    endif()

    if(("${_compiler_name}" MATCHES "^gcc")
            OR ("${_compiler_name}" MATCHES "^clang"))
        message(STATUS "xrepo: set(XREPO_TOOLCHAIN ${_compiler_name}) because CMAKE_C_COMPILER or CMAKE_CXX_COMPILER is set")
        set(XREPO_TOOLCHAIN "${_compiler_name}")
    else()
        message(STATUS "xrepo: CMAKE_C_COMPILER=${CMAKE_C_COMPILER} CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} using system default toolchain.")
    endif()
endfunction()

function(_install_xmake_program)
    set(_xmake_binary_dir ${CMAKE_BINARY_DIR}/xmake)
    _xcmake_log("xmake not found, Install it to ${_xmake_binary_dir} automatically!")
    if(EXISTS "${_xmake_binary_dir}")
        file(REMOVE_RECURSE ${_xmake_binary_dir})
    endif()

    # Download xmake archive file
    if(WIN32)
        set(_xmake_archive_file ${CMAKE_BINARY_DIR}/xmake-master.win32.zip)
        set(_xmake_archive_link https://github.com/xmake-io/xmake/releases/download/v${XC_XMAKE_VERSION}/xmake-master.win32.zip)
    else()
        set(_xmake_archive_file ${CMAKE_BINARY_DIR}/xmake-master.tar.gz)
        set(_xmake_archive_link https://github.com/xmake-io/xmake/releases/download/v${XC_XMAKE_VERSION}/xmake-master.tar.gz)
    endif()

    if(NOT EXISTS "${_xmake_archive_file}")
        _xcmake_log("Downloading xmake from ${_xmake_archive_link}")
        file(DOWNLOAD "${_xmake_archive_link}"
                      "${_xmake_archive_file}"
                      TLS_VERIFY ON)
    endif()

    if(NOT EXISTS "${_xmake_binary_dir}")
        message(STATUS "Extracting ${_xmake_archive_file}")
        file(MAKE_DIRECTORY ${_xmake_binary_dir})
        execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${_xmake_archive_file}
            WORKING_DIRECTORY ${_xmake_binary_dir}
            RESULT_VARIABLE exit_code)

        if(NOT "${exit_code}" STREQUAL "0")
            _xcmake_fatal("unzip ${_xmake_archive_file} failed, exit code: ${exit_code}")
        endif()
    endif()

    if(WIN32)
        set(_xmake_binary ${_xmake_binary_dir}/xmake/xmake.exe)
        if(EXISTS ${_xmake_binary})
            set(XMAKE_CMD ${_xmake_binary})
        endif()
    else()
        set(XMAKE_SOURCE_DIR ${_xmake_binary_dir}/xmake-${XMAKE_RELEASE_LATEST})
        _xcmake_log("Configuring xmake")

        execute_process(COMMAND ${CMAKE_COMMAND} -E env --unset=CC --unset=CXX --unset=LD ./configure
            WORKING_DIRECTORY ${XMAKE_SOURCE_DIR}
            RESULT_VARIABLE exit_code)
        if(NOT "${exit_code}" STREQUAL "0")
            _xcmake_fatal("Configure xmake failed, exit code: ${exit_code}")
        endif()

        _xcmake_log("Building xmake")
        execute_process(COMMAND ${CMAKE_COMMAND} -E env --unset=CC --unset=CXX --unset=LD make -j4
            WORKING_DIRECTORY ${XMAKE_SOURCE_DIR}
            RESULT_VARIABLE exit_code)
        if(NOT "${exit_code}" STREQUAL "0")
            _xcmake_fatal("Build xmake failed, exit code: ${exit_code}")
        endif()

        _xcmake_log("Installing xmake")
        execute_process(COMMAND make install PREFIX=${_xmake_binary_dir}/install
            WORKING_DIRECTORY ${XMAKE_SOURCE_DIR}
            RESULT_VARIABLE exit_code)
        if(NOT "${exit_code}" STREQUAL "0")
            _xcmake_fatal("Install xmake failed, exit code: ${exit_code}")
        endif()

        set(_xmake_binary ${_xmake_binary_dir}/install/bin/xmake)
        if(EXISTS ${_xmake_binary})
            set(XMAKE_CMD ${_xmake_binary})
        endif()
    endif()
endfunction()

function(_detect_xmake_cmd)
    find_program(_xmake_cmd xmake)

    if(NOT _xmake_cmd)
        if(WIN32)
            set(_xmake_binary ${CMAKE_BINARY_DIR}/xmake/xmake/xmake.exe)
        else()
            set(_xmake_binary ${CMAKE_BINARY_DIR}/xmake/install/bin/xmake)
        endif()
        if(EXISTS ${_xmake_binary})
            set(_xmake_cmd ${_xmake_binary})
        endif()
    endif()

    if(NOT _xmake_cmd AND XREPO_BOOTSTRAP_XMAKE)
        _install_xmake_program()
    endif()

    if(NOT _xmake_cmd)
        _xcmake_fatal("xmake not found, Please install it first from https://xmake.io")
    endif()

    _xcmake_log("xmake command: ${_xmake_cmd}")
    set(XC_XMAKE_CMD "${_xmake_cmd}" CACHE INTERNAL "XMake path")
endfunction()

_detect_toolchain()
_detect_xmake_cmd()

#

function(_xcmake_generate_toolchain out_var)
    set(_cc "${CMAKE_C_COMPILER}")
    set(_cxx "${CMAKE_CXX_COMPILER}")
    set(_ar "${CMAKE_AR}")
    set(_strip "${CMAKE_STRIP}")

    if(NOT _cc)
        _xcmake_fatal("CMAKE_C_COMPILER not set, cannot generate xmake toolchain")
    endif()
    if(NOT _cxx)
        _xcmake_fatal("CMAKE_CXX_COMPILER not set, cannot generate xmake toolchain")
    endif()

    if(NOT _ar)
        find_program(_ar ar)
    endif()
    if(NOT _strip)
        find_program(_strip strip)
    endif()

    string(REPLACE "\\" "\\\\" _cc "${_cc}")
    string(REPLACE "\\" "\\\\" _cxx "${_cxx}")
    string(REPLACE "\\" "\\\\" _ar "${_ar}")
    string(REPLACE "\\" "\\\\" _strip "${_strip}")

    set(_toolchain_lua "\
toolchain(\"${XMAKE_TOOLCHAIN_NAME}\")
    set_kind(\"standalone\")
    set_toolset(\"cc\", \"${_cc}\")
    set_toolset(\"cxx\", \"${_cc}\", \"${_cxx}\")
    set_toolset(\"ld\", \"${_cxx}\", \"${_cc}\")
    set_toolset(\"sh\", \"${_cxx}\", \"${_cc}\")
toolchain_end()
")

    _xcmake_log("Generated xmake toolchain using cc=${_cc} cxx=${_cxx} ar=${_ar} strip=${_strip}")

    set(${out_var} "${_toolchain_lua}" PARENT_SCOPE)
endfunction()

function(_xcmake_generate_imports out_var)
    set(_imports "")
    foreach(_file IN LISTS ARGN)
        if(NOT EXISTS "${_file}")
            _xcmake_fatal("Import file not found: ${_file}")
        endif()
        file(READ "${_file}" _file_content)
        string(APPEND _imports "${_file_content}" "\n")
    endforeach()
    set(${out_var} "${_imports}" PARENT_SCOPE)
endfunction()

#

function(xcmake_require)
    set(optionArgs DEBUG)
    set(oneValArgs NAME ALIAS VERSION)
    set(multiValArgs CONFIGS IMPORTS)
    cmake_parse_arguments(B "${optionArgs}" "${oneValArgs}" "${multiValArgs}" ${ARGN})

    if(NOT B_NAME)
        _xcmake_fatal("xrepo_require: name required")
    endif()

    if(NOT B_ALIAS)
        set(B_ALIAS "${B_NAME}")
    endif()

    if(B_DEBUG)
        set(_debug "debug = true")
    else()
        set(_debug "debug = false")
    endif()

    if(B_CONFIGS)
        string(REPLACE ";" "," B_CONFIGS "${B_CONFIGS}")
    endif()
    
    set(_build_dir "${CMAKE_BINARY_DIR}/_xcmake/${B_ALIAS}")

    set(_xmake_input "xmake.lua")
    set(_dummy_file "_xmake-${B_ALIAS}-dummy.cpp")

    set(_input_script "${_build_dir}/${_xmake_input}")
    set(_dummy_input "${_build_dir}/${_dummy_file}")

    _xcmake_generate_imports(_imports ${B_IMPORTS})

    file(
        WRITE "${_input_script}"
        "\
${_toolchain}
set_warnings(\"none\")

${_imports}
add_requires(\"${B_NAME}\", {${_debug}, configs = {${B_CONFIGS}}, system = false})

target(\"${B_ALIAS}\")
    set_kind(\"object\")
    add_packages(\"${B_NAME}\")
    add_files(\"${_dummy_file}\")
")
    file(WRITE "${_dummy_input}" "")

    set(_toolchain "")
    if(XREPO_TOOLCHAIN)
        set(_toolchain "--toolchain=${XREPO_TOOLCHAIN}")
    endif ()

    _xcmake_execute_process(
            COMMAND
            ${XC_XMAKE_CMD}
            f -y ${_toolchain}
            WORKING_DIRECTORY
            ${_build_dir}
            RESULT_VARIABLE
            _xmake_result
            OUTPUT_VARIABLE
            _xmake_output
            ERROR_VARIABLE
            _xmake_output
    )
    if(NOT _xmake_result EQUAL 0)
        _xcmake_fatal("Failed to load configure xmake: ${_xmake_output}")
    endif()
    _xcmake_execute_process(
            COMMAND
            ${XC_XMAKE_CMD}
            project -k cmake -y
            WORKING_DIRECTORY
            ${_build_dir}
            RESULT_VARIABLE
            _xmake_result
            OUTPUT_VARIABLE
            _xmake_output
            ERROR_VARIABLE
            _xmake_output
    )
    if(NOT _xmake_result EQUAL 0)
        _xcmake_fatal("Failed to load configure xmake: ${_xmake_output}")
    endif()
    _xcmake_log("Configured xmake target: ${_xmake_output}")

    include(${_build_dir}/CMakeLists.txt)
endfunction()
