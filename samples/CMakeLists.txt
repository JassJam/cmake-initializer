
set(SUBDIRS
        hello_world
        hello_packages
        hello_shared_library
        hello_static_library
        hello_testing_frameworks
        hello_emscripten
)

foreach(subdir ${SUBDIRS})
    add_subdirectory(${subdir})
endforeach()
