include_guard(DIRECTORY)

find_program(CMAKE_FORMAT_EXE NAMES cmake-format)
find_package(Git QUIET)

if(CMAKE_FORMAT_EXE)
    file(
        GLOB_RECURSE CMAKE_FORMAT_SOURCES
        LIST_DIRECTORIES false
        ${CMAKE_SOURCE_DIR}/CMakeLists.txt ${CMAKE_SOURCE_DIR}/cmake/*.cmake
        ${CMAKE_SOURCE_DIR}/src/*/CMakeLists.txt
        ${CMAKE_SOURCE_DIR}/*/CMakeLists.txt)

    add_custom_target(
        format-cmake
        COMMAND ${CMAKE_FORMAT_EXE} -i ${CMAKE_FORMAT_SOURCES}
        COMMENT "Running cmake-format on all CMake files"
        VERBATIM)

    if(CMAKE_FORMAT_EXE AND Git_FOUND)
        add_custom_target(
            format-cmake-changed
            COMMAND
                bash -c
                "git diff --name-only --diff-filter=ACM HEAD -- '*.cmake' 'CMakeLists.txt' '**/CMakeLists.txt' | xargs -r ${CMAKE_FORMAT_EXE} -i"
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            COMMENT "Formatting only changed CMake files"
            VERBATIM)
    endif()

    add_custom_target(
        format-cmake-check
        COMMAND ${CMAKE_FORMAT_EXE} --check ${CMAKE_FORMAT_SOURCES}
        COMMENT "Checking CMake file formatting"
        VERBATIM)
else()
    message(
        STATUS
            "cmake-format not found; 'format-cmake' target will not be available"
    )
endif()
