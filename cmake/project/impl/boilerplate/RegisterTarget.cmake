include_guard(DIRECTORY)
include(${CMAKE_CURRENT_LIST_DIR}/CopySharedLibrary.cmake)

function(_register_target_common target)
    cmake_parse_arguments(PARSE_ARGV 1 ARG
        ""
        "NAMESPACE;EXPORT_SET;INSTALL_DESTINATION;CXX_STANDARD"
        "COMPILE_OPTIONS;COMPILE_DEFINITIONS;INCLUDE_DIRS;LINK_LIBS;PROPERTIES"
    )

    if(DEFINED ARG_CXX_STANDARD)
        set_target_properties(${target} PROPERTIES
            CXX_STANDARD          ${ARG_CXX_STANDARD}
            CXX_STANDARD_REQUIRED ON
            CXX_EXTENSIONS        OFF
        )
    endif()

    if(ARG_COMPILE_OPTIONS)
        target_compile_options(${target} ${ARG_COMPILE_OPTIONS})
    endif()

    if(ARG_COMPILE_DEFINITIONS)
        target_compile_definitions(${target} ${ARG_COMPILE_DEFINITIONS})
    endif()

    if(ARG_INCLUDE_DIRS)
        set(_vis PUBLIC)
        foreach(_inc IN LISTS ARG_INCLUDE_DIRS)
            if(_inc STREQUAL "PUBLIC" OR _inc STREQUAL "PRIVATE" OR _inc STREQUAL "INTERFACE")
                set(_vis "${_inc}")
            else()
                if(_vis STREQUAL "PRIVATE")
                    target_include_directories(${target} PRIVATE
                        "$<BUILD_INTERFACE:${_inc}>"
                    )
                elseif(_vis STREQUAL "INTERFACE")
                    target_include_directories(${target} INTERFACE
                        "$<BUILD_INTERFACE:${_inc}>"
                        "$<INSTALL_INTERFACE:include>"
                    )
                else()
                    target_include_directories(${target} PUBLIC
                        "$<BUILD_INTERFACE:${_inc}>"
                        "$<INSTALL_INTERFACE:include>"
                    )
                endif()
            endif()
        endforeach()
    endif()

    if(ARG_LINK_LIBS)
        target_link_libraries(${target} ${ARG_LINK_LIBS})
    endif()

    if(ARG_PROPERTIES)
        set_target_properties(${target} PROPERTIES ${ARG_PROPERTIES})
    endif()

    # Configure RPATH for shared library dependencies
    if(UNIX)
        set_target_properties(${target} PROPERTIES
            # Don't skip the full RPATH for the build tree
            SKIP_BUILD_RPATH FALSE
            # When building, don't use the install RPATH already
            BUILD_WITH_INSTALL_RPATH FALSE
            # Add the automatically determined parts of the RPATH
            # which point to directories outside the build tree to the install RPATH
            INSTALL_RPATH_USE_LINK_PATH TRUE
            # The RPATH to be used when installing - executables and libraries in same directory
            INSTALL_RPATH "$ORIGIN"
        )
    endif()

    _copy_shared_library_dependencies_to_build_dir(${target})

    if(DEFINED ARG_EXPORT_SET)
        set(_dest "${ARG_INSTALL_DESTINATION}")
        if(NOT _dest)
            # Sensible defaults per target type
            get_target_property(_type ${target} TYPE)
            if(_type STREQUAL "EXECUTABLE")
                set(_dest "bin")
            else()
                set(_dest "lib")
            endif()
        endif()

        set(_ns "")
        if(DEFINED ARG_NAMESPACE)
            set(_ns NAMESPACE "${ARG_NAMESPACE}::")
        endif()

        install(TARGETS ${target}
            EXPORT  ${ARG_EXPORT_SET}
            RUNTIME DESTINATION bin
            LIBRARY DESTINATION ${_dest}
            ARCHIVE DESTINATION ${_dest}
            # C++ module interface files (CMake 3.28+)
            CXX_MODULES_BMI DESTINATION lib/bmi
            FILE_SET HEADERS        DESTINATION include
            FILE_SET CXX_MODULES    DESTINATION include/modules
        )

        # Install the export set the first time it is encountered.
        # Callers should invoke install(EXPORT …) once after all targets are
        # registered; this block is a convenience for single-target projects.
        get_property(_exported_sets GLOBAL PROPERTY _REGISTER_EXPORTED_SETS)
        if(NOT ARG_EXPORT_SET IN_LIST _exported_sets)
            list(APPEND _exported_sets ${ARG_EXPORT_SET})
            set_property(GLOBAL PROPERTY _REGISTER_EXPORTED_SETS "${_exported_sets}")

            install(EXPORT ${ARG_EXPORT_SET}
                FILE        "${ARG_EXPORT_SET}Targets.cmake"
                ${_ns}
                DESTINATION "lib/cmake/${ARG_EXPORT_SET}"
            )
        endif()
    endif()
endfunction()


# ──────────────────────────────────────────────────────────────────────────────
# _register_forward_quality_opts(<target> <ARG_prefix>)
# Collects the quality/analysis kwargs and calls target_setup_common_options()
# if it exists, otherwise silently skips (project may not use that helper).
# ──────────────────────────────────────────────────────────────────────────────
macro(_register_forward_quality_opts target)
    set(_quality_args)
    foreach(_q
        ENABLE_EXCEPTIONS ENABLE_IPO WARNINGS_AS_ERRORS
        ENABLE_SANITIZER_ADDRESS ENABLE_SANITIZER_LEAK
        ENABLE_SANITIZER_UNDEFINED_BEHAVIOR ENABLE_SANITIZER_THREAD
        ENABLE_SANITIZER_MEMORY ENABLE_HARDENING
        ENABLE_CLANG_TIDY ENABLE_CPPCHECK
    )
        if(DEFINED ARG_${_q})
            list(APPEND _quality_args ${_q} ${ARG_${_q}})
        endif()
    endforeach()

    if(_quality_args AND COMMAND target_setup_common_options)
        target_setup_common_options(${target} ${_quality_args})
    endif()
    unset(_quality_args)
    unset(_q)
endmacro()


# ──────────────────────────────────────────────────────────────────────────────
# register_header_only_library(<name>
#     [HEADERS            <file> …]
#     [INCLUDE_DIRS       <dir>  …]
#     [LINK_LIBS          <tgt>  …]
#     [COMPILE_DEFINITIONS <def> …]
#     [PROPERTIES         <key val> …]
#     [NAMESPACE          <ns>]
#     [EXPORT_SET         <set>]       install + add to named export set
#     [INSTALL_DESTINATION <dir>]
# )
# ──────────────────────────────────────────────────────────────────────────────
function(register_header_only_library name)
    cmake_parse_arguments(PARSE_ARGV 1 ARG
        ""
        "NAMESPACE;EXPORT_SET;INSTALL_DESTINATION;CXX_STANDARD"
        "HEADERS;INCLUDE_DIRS;LINK_LIBS;COMPILE_DEFINITIONS;PROPERTIES"
    )

    add_library(${name} INTERFACE)
    add_library(${name}::${name} ALIAS ${name})

    if(ARG_HEADERS)
        target_sources(${name} INTERFACE
            FILE_SET HEADERS
            BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}"
            FILES     ${ARG_HEADERS}
        )
    endif()

    if(ARG_INCLUDE_DIRS)
        target_include_directories(${name} INTERFACE
            "$<BUILD_INTERFACE:${ARG_INCLUDE_DIRS}>"
            "$<INSTALL_INTERFACE:include>"
        )
    endif()

    if(ARG_LINK_LIBS)
        target_link_libraries(${name} INTERFACE ${ARG_LINK_LIBS})
    endif()

    if(ARG_COMPILE_DEFINITIONS)
        target_compile_definitions(${name} INTERFACE ${ARG_COMPILE_DEFINITIONS})
    endif()

    if(ARG_PROPERTIES)
        set_target_properties(${name} PROPERTIES ${ARG_PROPERTIES})
    endif()

    set(_forward)
    foreach(_kw NAMESPACE EXPORT_SET INSTALL_DESTINATION CXX_STANDARD)
        if(DEFINED ARG_${_kw})
            list(APPEND _forward ${_kw} "${ARG_${_kw}}")
        endif()
    endforeach()

    _register_target_common(${name} ${_forward})
endfunction()


# ──────────────────────────────────────────────────────────────────────────────
# register_library(<name>
#     [STATIC | SHARED]
#     [SOURCES            <file> …]
#     [HEADERS            <file> …]
#     [CXX_MODULES        <file> …]
#     [INCLUDE_DIRS       <dir>  …]
#     [LINK_LIBS          <tgt>  …]
#     [CXX_STANDARD       <std>]       default: 23 with modules, else 17
#     [NAMESPACE          <ns>]
#     [EXPORT_SET         <set>]       install + add to named export set
#     [INSTALL_DESTINATION <dir>]
#     [COMPILE_OPTIONS     <opt> …]
#     [COMPILE_DEFINITIONS <def> …]
#     [PROPERTIES         <key val> …]
#     [EXPORT_HEADER      <relative/path/export.hpp>]
#                                      generates dllexport/dllimport/visibility
#                                      macros; see implementation for details
#     [EXPORT_MACRO_NAME  <MACRO>]     override the default <TARGETNAME>_EXPORT
#                                      macro name, e.g. MY_API or MYLIB_API
#     [ENABLE_EXCEPTIONS ON|OFF]
#     [ENABLE_IPO ON|OFF]
#     [WARNINGS_AS_ERRORS ON|OFF]
#     [ENABLE_SANITIZER_ADDRESS ON|OFF]
#     [ENABLE_SANITIZER_LEAK ON|OFF]
#     [ENABLE_SANITIZER_UNDEFINED_BEHAVIOR ON|OFF]
#     [ENABLE_SANITIZER_THREAD ON|OFF]
#     [ENABLE_SANITIZER_MEMORY ON|OFF]
#     [ENABLE_HARDENING ON|OFF]
#     [ENABLE_CLANG_TIDY ON|OFF]
#     [ENABLE_CPPCHECK ON|OFF]
# )
# ──────────────────────────────────────────────────────────────────────────────
function(register_library name)
    cmake_parse_arguments(PARSE_ARGV 1 ARG
        "STATIC;SHARED"
        "NAMESPACE;EXPORT_SET;INSTALL_DESTINATION;CXX_STANDARD;EXPORT_HEADER;EXPORT_MACRO_NAME"
        "SOURCES;HEADERS;CXX_MODULES;INCLUDE_DIRS;LINK_LIBS;COMPILE_OPTIONS;COMPILE_DEFINITIONS;PROPERTIES"
    )

    if(ARG_STATIC)
        set(_linkage STATIC)
    elseif(ARG_SHARED)
        set(_linkage SHARED)
    else()
        set(_linkage "")
    endif()

    add_library(${name} ${_linkage})
    add_library(${name}::${name} ALIAS ${name})

    if(ARG_SOURCES)
        target_sources(${name} PRIVATE ${ARG_SOURCES})
    endif()

    if(ARG_HEADERS)
        target_sources(${name} PUBLIC
            FILE_SET HEADERS
            BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}"
            FILES     ${ARG_HEADERS}
        )
    endif()

    if(ARG_CXX_MODULES)
        if(NOT DEFINED ARG_CXX_STANDARD)
            set(ARG_CXX_STANDARD 23)
        endif()
        target_sources(${name} PUBLIC
            FILE_SET CXX_MODULES
            BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}"
            FILES     ${ARG_CXX_MODULES}
        )
    endif()

    if(NOT DEFINED ARG_CXX_STANDARD)
        set(ARG_CXX_STANDARD 17)
    endif()

    target_include_directories(${name} PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
        "$<INSTALL_INTERFACE:include>"
    )

    # Generates a header in the build tree that defines a macro you use to
    # annotate your public API:
    #
    #   #include <mylib/export.hpp>
    #   class MYLIB_EXPORT Foo { … };   // default macro name
    #   class MY_API    Foo { … };      // with EXPORT_MACRO_NAME MY_API
    #
    # The macro resolves to:
    #   - building the shared lib  → __declspec(dllexport) / visibility("default")
    #   - consuming the shared lib → __declspec(dllimport) / (nothing on GCC/Clang)
    #   - static lib               → nothing
    if(DEFINED ARG_EXPORT_HEADER)
        include(GenerateExportHeader)

        set(_export_file "${CMAKE_CURRENT_BINARY_DIR}/${ARG_EXPORT_HEADER}")

        # Build optional args for generate_export_header
        set(_geh_extra)
        if(DEFINED ARG_EXPORT_MACRO_NAME)
            list(APPEND _geh_extra EXPORT_MACRO_NAME "${ARG_EXPORT_MACRO_NAME}")
        endif()

        generate_export_header(${name}
            EXPORT_FILE_NAME "${_export_file}"
            ${_geh_extra}
        )

        # Add the generated header into the PUBLIC FILE_SET so it is
        # installed alongside the hand-written headers.
        target_sources(${name} PUBLIC
            FILE_SET HEADERS
            BASE_DIRS "${CMAKE_CURRENT_BINARY_DIR}"
            FILES     "${_export_file}"
        )

        # Consumers need the binary dir on their include path to find the header.
        target_include_directories(${name} PUBLIC
            "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>"
            "$<INSTALL_INTERFACE:include>"
        )

        # For static builds suppress all decoration automatically.
        get_target_property(_lib_type ${name} TYPE)
        if(_lib_type STREQUAL "STATIC_LIBRARY")
            string(TOUPPER "${name}" _upper)
            target_compile_definitions(${name} PUBLIC ${_upper}_STATIC_DEFINE)
        endif()
    endif()

    set(_forward CXX_STANDARD ${ARG_CXX_STANDARD})
    foreach(_kw NAMESPACE EXPORT_SET INSTALL_DESTINATION)
        if(DEFINED ARG_${_kw})
            list(APPEND _forward ${_kw} "${ARG_${_kw}}")
        endif()
    endforeach()
    foreach(_mv INCLUDE_DIRS LINK_LIBS COMPILE_OPTIONS COMPILE_DEFINITIONS PROPERTIES)
        if(ARG_${_mv})
            list(APPEND _forward ${_mv} ${ARG_${_mv}})
        endif()
    endforeach()

    _register_target_common(${name} ${_forward})

    _register_forward_quality_opts(${name})
endfunction()


# ──────────────────────────────────────────────────────────────────────────────
# register_executable(<name>
#     [SOURCES            <file> …]
#     [HEADERS            <file> …]    IDE visibility; adds include/ automatically
#     [CXX_MODULES        <file> …]
#     [INCLUDE_DIRS       <dir>  …]
#     [LINK_LIBS          <tgt>  …]
#     [CXX_STANDARD       <std>]
#     [NAMESPACE          <ns>]
#     [EXPORT_SET         <set>]       install + add to named export set
#     [INSTALL]                        install without an export set
#     [INSTALL_DESTINATION <dir>]      default: bin
#     [COMPILE_OPTIONS     <opt> …]
#     [COMPILE_DEFINITIONS <def> …]
#     [PROPERTIES         <key val> …]
#     [ENABLE_EXCEPTIONS ON|OFF]
#     [ENABLE_IPO ON|OFF]
#     [WARNINGS_AS_ERRORS ON|OFF]
#     [ENABLE_SANITIZER_ADDRESS ON|OFF]
#     [ENABLE_SANITIZER_LEAK ON|OFF]
#     [ENABLE_SANITIZER_UNDEFINED_BEHAVIOR ON|OFF]
#     [ENABLE_SANITIZER_THREAD ON|OFF]
#     [ENABLE_SANITIZER_MEMORY ON|OFF]
#     [ENABLE_HARDENING ON|OFF]
#     [ENABLE_CLANG_TIDY ON|OFF]
#     [ENABLE_CPPCHECK ON|OFF]
# )
# ──────────────────────────────────────────────────────────────────────────────
function(register_executable name)
    cmake_parse_arguments(PARSE_ARGV 1 ARG
        ""
        "NAMESPACE;EXPORT_SET;INSTALL_DESTINATION;CXX_STANDARD;
         ENABLE_EXCEPTIONS;ENABLE_IPO;WARNINGS_AS_ERRORS;
         ENABLE_SANITIZER_ADDRESS;ENABLE_SANITIZER_LEAK;
         ENABLE_SANITIZER_UNDEFINED_BEHAVIOR;ENABLE_SANITIZER_THREAD;
         ENABLE_SANITIZER_MEMORY;ENABLE_HARDENING;
         ENABLE_CLANG_TIDY;ENABLE_CPPCHECK"
        "SOURCES;HEADERS;CXX_MODULES;INCLUDE_DIRS;LINK_LIBS;COMPILE_OPTIONS;COMPILE_DEFINITIONS;PROPERTIES"
    )

    add_executable(${name})

    if(ARG_SOURCES)
        target_sources(${name} PRIVATE ${ARG_SOURCES})
    endif()

    # Headers: PRIVATE FILE_SET for IDE visibility
    if(ARG_HEADERS)
        target_sources(${name} PRIVATE
            FILE_SET HEADERS
            BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}"
            FILES     ${ARG_HEADERS}
        )
    endif()

    if(ARG_CXX_MODULES)
        if(NOT DEFINED ARG_CXX_STANDARD)
            set(ARG_CXX_STANDARD 23)
        endif()
        target_sources(${name} PRIVATE
            FILE_SET CXX_MODULES
            BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}"
            FILES     ${ARG_CXX_MODULES}
        )
    endif()

    if(NOT DEFINED ARG_CXX_STANDARD)
        set(ARG_CXX_STANDARD 17)
    endif()

    if(NOT DEFINED ARG_INSTALL_DESTINATION)
        set(ARG_INSTALL_DESTINATION "bin")
    endif()

    set(_forward CXX_STANDARD ${ARG_CXX_STANDARD} INSTALL_DESTINATION ${ARG_INSTALL_DESTINATION})
    foreach(_kw NAMESPACE EXPORT_SET)
        if(DEFINED ARG_${_kw})
            list(APPEND _forward ${_kw} "${ARG_${_kw}}")
        endif()
    endforeach()
    foreach(_mv INCLUDE_DIRS LINK_LIBS COMPILE_OPTIONS COMPILE_DEFINITIONS PROPERTIES)
        if(ARG_${_mv})
            list(APPEND _forward ${_mv} ${ARG_${_mv}})
        endif()
    endforeach()

    _register_target_common(${name} ${_forward})

    _register_forward_quality_opts(${name})
endfunction()


# ──────────────────────────────────────────────────────────────────────────────
# register_test(<name>
#     [SOURCES            <file> …]
#     [HEADERS            <file> …]    IDE visibility; adds include/ automatically
#     [CXX_MODULES        <file> …]
#     [INCLUDE_DIRS       <dir>  …]
#     [LINK_LIBS          <tgt>  …]
#     [CXX_STANDARD       <std>]
#     [COMPILE_OPTIONS     <opt> …]
#     [COMPILE_DEFINITIONS <def> …]
#     [PROPERTIES         <key val> …]
#     [TEST_ARGS          <arg> …]
#     [WORKING_DIRECTORY  <dir>]
#     [LABELS             <label> …]
#     [TIMEOUT            <seconds>]
#     [ENVIRONMENT        <VAR=val> …]
#     [ENABLE_EXCEPTIONS ON|OFF]
#     [ENABLE_IPO ON|OFF]
#     [WARNINGS_AS_ERRORS ON|OFF]
#     [ENABLE_SANITIZER_ADDRESS ON|OFF]
#     [ENABLE_SANITIZER_LEAK ON|OFF]
#     [ENABLE_SANITIZER_UNDEFINED_BEHAVIOR ON|OFF]
#     [ENABLE_SANITIZER_THREAD ON|OFF]
#     [ENABLE_SANITIZER_MEMORY ON|OFF]
#     [ENABLE_HARDENING ON|OFF]
#     [ENABLE_CLANG_TIDY ON|OFF]
#     [ENABLE_CPPCHECK ON|OFF]
# )
# ──────────────────────────────────────────────────────────────────────────────
function(register_test name)
    cmake_parse_arguments(PARSE_ARGV 1 ARG
        ""
        "CXX_STANDARD;WORKING_DIRECTORY;TIMEOUT;
         ENABLE_EXCEPTIONS;ENABLE_IPO;WARNINGS_AS_ERRORS;
         ENABLE_SANITIZER_ADDRESS;ENABLE_SANITIZER_LEAK;
         ENABLE_SANITIZER_UNDEFINED_BEHAVIOR;ENABLE_SANITIZER_THREAD;
         ENABLE_SANITIZER_MEMORY;ENABLE_HARDENING;
         ENABLE_CLANG_TIDY;ENABLE_CPPCHECK"
        "SOURCES;HEADERS;CXX_MODULES;INCLUDE_DIRS;LINK_LIBS;COMPILE_OPTIONS;COMPILE_DEFINITIONS;PROPERTIES;TEST_ARGS;LABELS;ENVIRONMENT"
    )

    add_executable(${name})

    if(ARG_SOURCES)
        target_sources(${name} PRIVATE ${ARG_SOURCES})
    endif()

    # Headers: PRIVATE FILE_SET for IDE visibility
    if(ARG_HEADERS)
        target_sources(${name} PRIVATE
            FILE_SET HEADERS
            BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}"
            FILES     ${ARG_HEADERS}
        )
    endif()

    # Auto include path
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include")
        target_include_directories(${name} PRIVATE
            "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
        )
    endif()

    if(ARG_CXX_MODULES)
        if(NOT DEFINED ARG_CXX_STANDARD)
            set(ARG_CXX_STANDARD 23)
        endif()
        target_sources(${name} PRIVATE
            FILE_SET CXX_MODULES
            BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}"
            FILES     ${ARG_CXX_MODULES}
        )
    endif()

    if(NOT DEFINED ARG_CXX_STANDARD)
        set(ARG_CXX_STANDARD 17)
    endif()

    set(_forward CXX_STANDARD ${ARG_CXX_STANDARD})
    foreach(_mv INCLUDE_DIRS LINK_LIBS COMPILE_OPTIONS COMPILE_DEFINITIONS PROPERTIES)
        if(ARG_${_mv})
            list(APPEND _forward ${_mv} ${ARG_${_mv}})
        endif()
    endforeach()

    _register_target_common(${name} ${_forward})

    _register_forward_quality_opts(${name})

    # CTest registration
    set(_wd "${CMAKE_CURRENT_BINARY_DIR}")
    if(DEFINED ARG_WORKING_DIRECTORY)
        set(_wd "${ARG_WORKING_DIRECTORY}")
    endif()

    add_test(
        NAME              ${name}
        COMMAND           ${name} ${ARG_TEST_ARGS}
        WORKING_DIRECTORY "${_wd}"
    )

    if(ARG_LABELS)
        set_tests_properties(${name} PROPERTIES LABELS "${ARG_LABELS}")
    endif()

    if(DEFINED ARG_TIMEOUT)
        set_tests_properties(${name} PROPERTIES TIMEOUT ${ARG_TIMEOUT})
    endif()

    if(ARG_ENVIRONMENT)
        set_tests_properties(${name} PROPERTIES ENVIRONMENT "${ARG_ENVIRONMENT}")
    endif()
endfunction()