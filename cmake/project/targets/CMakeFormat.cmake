find_program(CMAKE_FORMAT_EXE NAMES cmake-format)

if(CMAKE_FORMAT_EXE)
    file(GLOB_RECURSE CMAKE_FORMAT_SOURCES
        LIST_DIRECTORIES false
        ${CMAKE_SOURCE_DIR}/CMakeLists.txt
        ${CMAKE_SOURCE_DIR}/cmake/*.cmake
        ${CMAKE_SOURCE_DIR}/src/*/CMakeLists.txt
        ${CMAKE_SOURCE_DIR}/*/CMakeLists.txt
    )

    add_custom_target(format-cmake
        COMMAND ${CMAKE_FORMAT_EXE} -i ${CMAKE_FORMAT_SOURCES}
        COMMENT "Running cmake-format on all CMake files"
        VERBATIM
    )
else()
    message(STATUS "cmake-format not found; 'format-cmake' target will not be available")
endif()
