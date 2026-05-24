include_guard(DIRECTORY)
include(${CMAKE_CURRENT_LIST_DIR}/CopySharedLibrary.cmake)

function(_register_target_common target)
    cmake_parse_arguments(PARSE_ARGV 1 ARG
        ""                              # options
        "NAMESPACE;EXPORT_SET;INSTALL_DESTINATION;CXX_STANDARD"
        "COMPILE_OPTIONS;COMPILE_DEFINITIONS;INCLUDE_DIRS;LINK_LIBS;PROPERTIES"
    )

    # ── C++ standard ──────────────────────────────────────────────────────────
    if(DEFINED ARG_CXX_STANDARD)
        set_target_properties(${target} PROPERTIES
            CXX_STANDARD          ${ARG_CXX_STANDARD}
            CXX_STANDARD_REQUIRED ON
            CXX_EXTENSIONS        OFF
        )
    endif()

    # ── Extra compile options / definitions ───────────────────────────────────
    if(ARG_COMPILE_OPTIONS)
        target_compile_options(${target} PRIVATE ${ARG_COMPILE_OPTIONS})
    endif()

    if(ARG_COMPILE_DEFINITIONS)
        target_compile_definitions(${target} PRIVATE ${ARG_COMPILE_DEFINITIONS})
    endif()

    # ── Additional include directories ────────────────────────────────────────
    if(ARG_INCLUDE_DIRS)
        target_include_directories(${target} PUBLIC
            "$<BUILD_INTERFACE:${ARG_INCLUDE_DIRS}>"
            "$<INSTALL_INTERFACE:include>"
        )
    endif()

    # ── Link libraries ────────────────────────────────────────────────────────
    if(ARG_LINK_LIBS)
        target_link_libraries(${target} PUBLIC ${ARG_LINK_LIBS})
    endif()

    # ── Arbitrary target properties ───────────────────────────────────────────
    if(ARG_PROPERTIES)
        set_target_properties(${target} PROPERTIES ${ARG_PROPERTIES})
    endif()

    # Configure RPATH for shared library dependencies
    if (UNIX)
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
    endif ()

    # Copy shared library dependencies to build directory for direct execution
    _copy_shared_library_dependencies_to_build_dir(${target})

    # ── Install + export (optional) ───────────────────────────────────────────
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
# register_header_only_library(<name>
#     HEADERS         <file> …
#     [INCLUDE_DIRS   <dir>  …]
#     [LINK_LIBS      <tgt>  …]
#     [NAMESPACE      <ns>]
#     [EXPORT_SET     <set>]
#     [COMPILE_DEFINITIONS <def> …]
#     [PROPERTIES     <key val> …]
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
        # FILE_SET (CMake 3.23+) so headers are installed correctly
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

    # Propagate install/export args
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
#     SOURCES         <file> …
#     [HEADERS        <file> …]
#     [CXX_MODULES    <file> …]   ← C++20 named module sources (.cppm/.ixx)
#     [INCLUDE_DIRS   <dir>  …]
#     [LINK_LIBS      <tgt>  …]
#     [CXX_STANDARD   <std>]      (default: 23 when CXX_MODULES used, else 17)
#     [NAMESPACE      <ns>]
#     [EXPORT_SET     <set>]
#     [INSTALL_DESTINATION <dir>]
#     [COMPILE_OPTIONS     <opt> …]
#     [COMPILE_DEFINITIONS <def> …]
#     [PROPERTIES     <key val> …]
# )
# ──────────────────────────────────────────────────────────────────────────────
function(register_library name)
    cmake_parse_arguments(PARSE_ARGV 1 ARG
        "STATIC;SHARED"
        "NAMESPACE;EXPORT_SET;INSTALL_DESTINATION;CXX_STANDARD"
        "SOURCES;HEADERS;CXX_MODULES;INCLUDE_DIRS;LINK_LIBS;COMPILE_OPTIONS;COMPILE_DEFINITIONS;PROPERTIES"
    )

    # Determine linkage
    if(ARG_STATIC)
        set(_linkage STATIC)
    elseif(ARG_SHARED)
        set(_linkage SHARED)
    else()
        set(_linkage "")
    endif()

    add_library(${name} ${_linkage})
    add_library(${name}::${name} ALIAS ${name})

    # ── Regular sources ───────────────────────────────────────────────────────
    if(ARG_SOURCES)
        target_sources(${name} PRIVATE ${ARG_SOURCES})
    endif()

    # ── Public headers via FILE_SET ───────────────────────────────────────────
    if(ARG_HEADERS)
        target_sources(${name} PUBLIC
            FILE_SET HEADERS
            BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}"
            FILES     ${ARG_HEADERS}
        )
    endif()

    # ── C++20 named modules ───────────────────────────────────────────────────
    if(ARG_CXX_MODULES)
        # Require at least C++20; bump to 23 when not set explicitly
        if(NOT DEFINED ARG_CXX_STANDARD)
            set(ARG_CXX_STANDARD 23)
        endif()

        target_sources(${name} PUBLIC
            FILE_SET CXX_MODULES
            BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}"
            FILES     ${ARG_CXX_MODULES}
        )
    endif()

    # ── Default standard ──────────────────────────────────────────────────────
    if(NOT DEFINED ARG_CXX_STANDARD)
        set(ARG_CXX_STANDARD 17)
    endif()

    # ── Include directories ───────────────────────────────────────────────────
    target_include_directories(${name}
        PUBLIC
            "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
            "$<INSTALL_INTERFACE:include>"
    )

    # ── Forward to common helper ──────────────────────────────────────────────
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
endfunction()


# ──────────────────────────────────────────────────────────────────────────────
# register_executable(<name>
#     SOURCES         <file> …
#     [CXX_MODULES    <file> …]
#     [INCLUDE_DIRS   <dir>  …]
#     [LINK_LIBS      <tgt>  …]
#     [CXX_STANDARD   <std>]
#     [NAMESPACE      <ns>]
#     [EXPORT_SET     <set>]
#     [INSTALL_DESTINATION <dir>]   (default: bin)
#     [COMPILE_OPTIONS     <opt> …]
#     [COMPILE_DEFINITIONS <def> …]
#     [PROPERTIES     <key val> …]
#
#     # Sanity and analysis options
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
        "NAMESPACE;EXPORT_SET;INSTALL_DESTINATION;CXX_STANDARD"
        "SOURCES;CXX_MODULES;INCLUDE_DIRS;LINK_LIBS;COMPILE_OPTIONS;COMPILE_DEFINITIONS;PROPERTIES"
    )

    add_executable(${name})

    if(ARG_SOURCES)
        target_sources(${name} PRIVATE ${ARG_SOURCES})
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

    # Apply common project options (warnings, sanitizers, static analysis, etc.)
    set(COMMON_OPTIONS_ARGS)
    if (DEFINED ARG_ENABLE_EXCEPTIONS)
        list(APPEND COMMON_OPTIONS_ARGS ENABLE_EXCEPTIONS ${ARG_ENABLE_EXCEPTIONS})
    endif ()
    if (DEFINED ARG_ENABLE_IPO)
        list(APPEND COMMON_OPTIONS_ARGS ENABLE_IPO ${ARG_ENABLE_IPO})
    endif ()
    if (DEFINED ARG_WARNINGS_AS_ERRORS)
        list(APPEND COMMON_OPTIONS_ARGS WARNINGS_AS_ERRORS ${ARG_WARNINGS_AS_ERRORS})
    endif ()
    if (DEFINED ARG_ENABLE_SANITIZER_ADDRESS)
        list(APPEND COMMON_OPTIONS_ARGS ENABLE_SANITIZER_ADDRESS ${ARG_ENABLE_SANITIZER_ADDRESS})
    endif ()
    if (DEFINED ARG_ENABLE_SANITIZER_LEAK)
        list(APPEND COMMON_OPTIONS_ARGS ENABLE_SANITIZER_LEAK ${ARG_ENABLE_SANITIZER_LEAK})
    endif ()
    if (DEFINED ARG_ENABLE_SANITIZER_UNDEFINED_BEHAVIOR)
        list(APPEND COMMON_OPTIONS_ARGS ENABLE_SANITIZER_UNDEFINED_BEHAVIOR ${ARG_ENABLE_SANITIZER_UNDEFINED_BEHAVIOR})
    endif ()
    if (DEFINED ARG_ENABLE_SANITIZER_THREAD)
        list(APPEND COMMON_OPTIONS_ARGS ENABLE_SANITIZER_THREAD ${ARG_ENABLE_SANITIZER_THREAD})
    endif ()
    if (DEFINED ARG_ENABLE_SANITIZER_MEMORY)
        list(APPEND COMMON_OPTIONS_ARGS ENABLE_SANITIZER_MEMORY ${ARG_ENABLE_SANITIZER_MEMORY})
    endif ()
    if (DEFINED ARG_ENABLE_HARDENING)
        list(APPEND COMMON_OPTIONS_ARGS ENABLE_HARDENING ${ARG_ENABLE_HARDENING})
    endif ()
    if (DEFINED ARG_ENABLE_CLANG_TIDY)
        list(APPEND COMMON_OPTIONS_ARGS ENABLE_CLANG_TIDY ${ARG_ENABLE_CLANG_TIDY})
    endif ()
    if (DEFINED ARG_ENABLE_CPPCHECK)
        list(APPEND COMMON_OPTIONS_ARGS ENABLE_CPPCHECK ${ARG_ENABLE_CPPCHECK})
    endif ()

    _register_target_common(${name} ${_forward})
endfunction()

# ──────────────────────────────────────────────────────────────────────────────
# register_test(<name>
#     SOURCES         <file> …
#     [CXX_MODULES    <file> …]
#     [INCLUDE_DIRS   <dir>  …]
#     [LINK_LIBS      <tgt>  …]
#     [CXX_STANDARD   <std>]
#     [COMPILE_OPTIONS     <opt> …]
#     [COMPILE_DEFINITIONS <def> …]
#     [PROPERTIES     <key val> …]
#
#     # CTest integration
#     [TEST_ARGS      <arg> …]      passed to add_test() as COMMAND args
#     [WORKING_DIRECTORY <dir>]     working dir for the test runner
#     [LABELS         <label> …]    CTest LABELS (e.g. "unit" "integration")
#     [TIMEOUT        <seconds>]    CTest TIMEOUT property
#     [ENVIRONMENT    <VAR=val> …]  CTest ENVIRONMENT property
#
#     # Sanity and analysis options (same as register_executable)
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
        "CXX_STANDARD;WORKING_DIRECTORY;TIMEOUT"
        "SOURCES;CXX_MODULES;INCLUDE_DIRS;LINK_LIBS;COMPILE_OPTIONS;COMPILE_DEFINITIONS;PROPERTIES;TEST_ARGS;LABELS;ENVIRONMENT"
    )

    add_executable(${name})

    if(ARG_SOURCES)
        target_sources(${name} PRIVATE ${ARG_SOURCES})
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

    # Apply common project options (warnings, sanitizers, static analysis, etc.)
    set(COMMON_OPTIONS_ARGS)
    foreach(_opt
        ENABLE_EXCEPTIONS ENABLE_IPO WARNINGS_AS_ERRORS
        ENABLE_SANITIZER_ADDRESS ENABLE_SANITIZER_LEAK
        ENABLE_SANITIZER_UNDEFINED_BEHAVIOR ENABLE_SANITIZER_THREAD
        ENABLE_SANITIZER_MEMORY ENABLE_HARDENING
        ENABLE_CLANG_TIDY ENABLE_CPPCHECK
    )
        if(DEFINED ARG_${_opt})
            list(APPEND COMMON_OPTIONS_ARGS ${_opt} ${ARG_${_opt}})
        endif()
    endforeach()

    _register_target_common(${name} ${_forward})

    # ── CTest registration ─────────────────────────────────────────────────────
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