register_executable(HelloWorld
    SOURCES
        src/main.cpp
        include/hello_world.hpp
    INCLUDE_DIRS
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    NAMESPACE    ${THIS_PROJECT_NAMESPACE}
    EXPORT_SET   "${THIS_PROJECT_NAMESPACE}Targets"
    INSTALL
)

include(LoadEnvVariable)
target_load_env_files_with_fallback(HelloWorld "${CMAKE_CURRENT_LIST_DIR}/.env")
