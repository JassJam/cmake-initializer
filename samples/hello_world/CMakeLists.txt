register_executable(HelloWorld INSTALL)

include(LoadEnvVariable)
target_load_env_files_with_fallback(HelloWorld "${CMAKE_CURRENT_LIST_DIR}/.env")
