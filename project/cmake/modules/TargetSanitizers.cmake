include(CMakeParseArguments)

#
# Enable sanitizers for the targets
# usage:
# targets_enable_sanitizers(
#   TARGETS <target ...>
#   ENABLE_SANITIZER_ADDRESS]
#   ENABLE_SANITIZER_LEAK]
#   ENABLE_SANITIZER_UNDEFINED_BEHAVIOR]
#   ENABLE_SANITIZER_THREAD]
#   ENABLE_SANITIZER_MEMORY]
# )
function(
    targets_enable_sanitizers
)
    set(oneValueArgs
        ENABLE_SANITIZER_ADDRESS
        ENABLE_SANITIZER_LEAK
        ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
        ENABLE_SANITIZER_THREAD
        ENABLE_SANITIZER_MEMORY
    )
    set(multiValueArgs
        TARGETS
    )
    cmake_parse_arguments(
        ARG
        ""
        ${oneValueArgs}
        ${multiValueArgs}
        ${ARGN}
    )

    get_current_compiler(CURRENT_COMPILER)

    #

    if (ARG_ENABLE_SANITIZER_ADDRESS)
        list(APPEND LIST_OF_SANITIZERS "address")
    endif()

    if ({ARG_ENABLE_SANITIZER_LEAK)
        if ("${CURRENT_COMPILER}" STREQUAL "MSVC")
            message(WARNING "Leak sanitizer is not supported on MSVC")
         else ()
            list(APPEND LIST_OF_SANITIZERS "leak")
        endif ()
    endif()

    if (ARG_ENABLE_SANITIZER_UNDEFINED_BEHAVIOR)
        if ("${CURRENT_COMPILER}" STREQUAL "MSVC")
            message(WARNING "Undefined behavior sanitizer is not supported on MSVC")
        else ()
            list(APPEND LIST_OF_SANITIZERS "undefined")
        endif ()
    endif()

    if (ARG_ENABLE_SANITIZER_THREAD)
        if ("${CURRENT_COMPILER}" STREQUAL "MSVC")
            message(WARNING "Thread sanitizer is not supported on MSVC")
        else ()
            list(APPEND LIST_OF_SANITIZERS "thread")
        endif ()
    endif()

    if (ARG_ENABLE_SANITIZER_MEMORY)
        if ("${CURRENT_COMPILER}" STREQUAL "MSVC")
            message(WARNING "Memory sanitizer is not supported on MSVC")
        elseif ("${CURRENT_COMPILER}" STREQUAL "Clang")
            message(WARNING
                "Memory sanitizer requires all the code (including libc++) to be MSan-instrumented otherwise it reports false positives"
            )

            if (${ARG_ENABLE_SANITIZER_ADDRESS} OR ${ARG_ENABLE_SANITIZER_THREAD} OR ${ARG_ENABLE_SANITIZER_LEAK})
                message(WARNING "Memory sanitizer does not work with Address, Thread or Leak sanitizer enabled")
            else()
                list(APPEND LIST_OF_SANITIZERS "memory")
            endif()
        endif ()
    endif()

    # if LIST_OF_SANITIZERS is empty
    if (NOT LIST_OF_SANITIZERS)
        message(WARNING "No sanitizers enabled")
        return()
    endif()

    message(STATUS "Sanitizers enabled: ${LIST_OF_SANITIZERS} for ${ARG_TARGETS}")

    # MSVC sanitizers
    if ("${CURRENT_COMPILER}" STREQUAL "MSVC")
        # replace LIST_OF_SANITIZERS with /fsanitize=address,...
        string(REPLACE ";" "," SANITIZER_FLAGS "${LIST_OF_SANITIZERS}")
        # append /fsanitize= to the string and /Zi and /INCREMENTAL:NO
        set(SANITIZER_FLAGS "/fsanitize=${SANITIZER_FLAGS} /Zi /INCREMENTAL:NO")

    elseif ("${CURRENT_COMPILER}" MATCHES "Clang|GCC")
        # replace LIST_OF_SANITIZERS with -fsanitize=address,...
        string(REPLACE ";" "," SANITIZER_FLAGS "${LIST_OF_SANITIZERS}")
        # append -fsanitize= to the string
        set(SANITIZER_FLAGS "-fsanitize=${SANITIZER_FLAGS}")
    endif()
    
    foreach (target ${ARG_TARGETS})
        if (NOT target)
            message(FATAL_ERROR "No target specified")
        endif()

        if (NOT TARGET ${target})
            message(FATAL_ERROR "Target ${target} not found")
        endif()

        target_compile_options(${target} INTERFACE ${SANITIZER_FLAGS})

        if (${CURRENT_COMPILER} STREQUAL "MSVC")
            string(FIND "$ENV{PATH}" "$ENV{VSINSTALLDIR}" INDEX_OF_VS_INSTALL_DIR)
            if ("${INDEX_OF_VS_INSTALL_DIR}" STREQUAL "-1")
                message(SEND_ERROR
                    "Using MSVC sanitizers requires setting the MSVC environment before building the project. Please manually open the MSVC command prompt and rebuild the project."
                )
            endif()

            target_compile_definitions(${target} INTERFACE _DISABLE_VECTOR_ANNOTATION _DISABLE_STRING_ANNOTATION)
            target_link_options(${target} INTERFACE /INCREMENTAL:NO)
        else()
            target_link_options(${target} INTERFACE ${SANITIZER_FLAGS})
        endif()
     endforeach()
endfunction()
