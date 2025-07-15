# ==============================================================================
# Load environment variables from .env files
# ==============================================================================

# usage:
#  target_load_env_file(TARGET FILENAME)
function(target_load_env_file TARGET_NAME FILENAME)
    if(NOT TARGET_NAME)
        message(FATAL_ERROR "target '${TARGET_NAME}' must be specified for load_env_file")
        return()
    endif()

    if(EXISTS "${FILENAME}")
        file(READ "${FILENAME}" ENV_CONTENTS)
        string(REPLACE "\n" ";" ENV_LINES "${ENV_CONTENTS}")

        foreach(line IN LISTS ENV_LINES)
            string(REGEX MATCH "^([A-Za-z_][A-Za-z0-9_]*)=(.*)$" _match "${line}")
            if(_match)
                string(REGEX REPLACE "^([A-Za-z_][A-Za-z0-9_]*)=(.*)$" "\\1" ENV_KEY "${line}")
                string(REGEX REPLACE "^([A-Za-z_][A-Za-z0-9_]*)=(.*)$" "\\2" ENV_VAL "${line}")
                target_compile_definitions(${TARGET_NAME} PRIVATE "${ENV_KEY}=${ENV_VAL}")
            endif()
        endforeach()
    endif()
endfunction()

# usage:
#  target_load_env_files(
#   TARGET FILENAMES...)
function(target_load_env_files TARGET_NAME)
    if(NOT TARGET_NAME)
        message(FATAL_ERROR "target '${TARGET_NAME}' must be specified for load_env_file")
        return()
    endif()

    foreach(filename IN LISTS ARGN)
        target_load_env_file(${TARGET_NAME} ${filename})
    endforeach()
endfunction()