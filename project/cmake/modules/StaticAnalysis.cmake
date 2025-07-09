#
# Static analysis tools setup (clang-tidy, cppcheck)
#
function(enable_static_analysis)
    set(options FOR_ALL_TARGETS)
    set(oneValueArgs TARGET)
    set(multiValueArgs TARGETS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    if(ARG_FOR_ALL_TARGETS)
        message(STATUS "** Enabling static analysis globally")
        set(targets "")
    elseif(ARG_TARGET)
        set(targets ${ARG_TARGET})
    elseif(ARG_TARGETS)
        set(targets ${ARG_TARGETS})
    else()
        message(FATAL_ERROR "enable_static_analysis: Must specify TARGET, TARGETS, or FOR_ALL_TARGETS")
    endif()

    # clang-tidy setup
    if(ENABLE_CLANG_TIDY)
        find_program(CLANG_TIDY_EXE NAMES "clang-tidy")
        if(CLANG_TIDY_EXE)
            message(STATUS "** clang-tidy found: ${CLANG_TIDY_EXE}")
            if(ARG_FOR_ALL_TARGETS)
                set(CMAKE_CXX_CLANG_TIDY 
                    ${CLANG_TIDY_EXE};
                    --config-file=${CMAKE_SOURCE_DIR}/.clang-tidy;
                    --header-filter=.*
                    PARENT_SCOPE)
            else()
                foreach(target ${targets})
                    if(TARGET ${target})
                        set_target_properties(${target} PROPERTIES
                            CXX_CLANG_TIDY "${CLANG_TIDY_EXE};--config-file=${CMAKE_SOURCE_DIR}/.clang-tidy;--header-filter=.*"
                        )
                        message(STATUS "** clang-tidy enabled for target: ${target}")
                    endif()
                endforeach()
            endif()
        else()
            message(WARNING "clang-tidy requested but not found")
        endif()
    endif()

    # cppcheck setup
    if(ENABLE_CPPCHECK)
        find_program(CPPCHECK_EXE NAMES "cppcheck")
        if(CPPCHECK_EXE)
            message(STATUS "** cppcheck found: ${CPPCHECK_EXE}")
            if(ARG_FOR_ALL_TARGETS)
                set(CMAKE_CXX_CPPCHECK 
                    ${CPPCHECK_EXE};
                    --enable=warning,performance,portability,information,missingInclude;
                    --std=c++${CMAKE_CXX_STANDARD};
                    --template=gcc;
                    --verbose;
                    --quiet;
                    --suppressions-list=${CMAKE_SOURCE_DIR}/.cppcheck-suppressions
                    PARENT_SCOPE)
            else()
                foreach(target ${targets})
                    if(TARGET ${target})
                        set_target_properties(${target} PROPERTIES
                            CXX_CPPCHECK "${CPPCHECK_EXE};--enable=warning,performance,portability,information,missingInclude;--std=c++${CMAKE_CXX_STANDARD};--template=gcc;--verbose;--quiet"
                        )
                        message(STATUS "** cppcheck enabled for target: ${target}")
                    endif()
                endforeach()
            endif()
        else()
            message(WARNING "cppcheck requested but not found")
        endif()
    endif()
endfunction()
