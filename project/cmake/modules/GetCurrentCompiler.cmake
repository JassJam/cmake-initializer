include(CMakeParseArguments)

#
# Easy helper to get the current compiler
# usage:
# get_current_compiler(
#   CURRENT_COMPILER
#   [INCLUDE_VERSION]         # Also includes compiler version info
#   [DEFAULT "UNKNOWN"]       # Sets a default value for unknown compilers
# )
# where CURRENT_COMPILER contains either MSVC, CLANG, GCC, or EMSCRIPTEN
#
function(get_current_compiler OUTPUT_VARIABLE)
  # Parse arguments
  set(options INCLUDE_VERSION)
  set(oneValueArgs DEFAULT)
  set(multiValueArgs)
  
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  
  # Set default unknown value
  if (NOT DEFINED ARG_DEFAULT)
    set(UNKNOWN_COMPILER "UNKNOWN")
  else()
    set(UNKNOWN_COMPILER "${ARG_DEFAULT}")
  endif()
  
  # Detect compiler
  if (CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
    set(DETECTED_COMPILER "MSVC")
    set(COMPILER_VERSION ${MSVC_VERSION})
    #
  elseif (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    set(DETECTED_COMPILER "CLANG")
    set(COMPILER_VERSION ${CMAKE_CXX_COMPILER_VERSION})
    #
  elseif (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    set(DETECTED_COMPILER "GCC")
    set(COMPILER_VERSION ${CMAKE_CXX_COMPILER_VERSION})
    #
  elseif (CMAKE_CXX_COMPILER_ID MATCHES "Emscripten" OR EMSCRIPTEN)
    set(DETECTED_COMPILER "EMSCRIPTEN")
    set(COMPILER_VERSION ${CMAKE_CXX_COMPILER_VERSION})
    #
  else ()
    message(WARNING "Unsupported compiler: ${CMAKE_CXX_COMPILER_ID}")
    set(DETECTED_COMPILER "${UNKNOWN_COMPILER}")
    set(COMPILER_VERSION "")
  endif()
  
  # Add version info if requested
  if (ARG_INCLUDE_VERSION AND
    NOT DETECTED_COMPILER STREQUAL "${UNKNOWN_COMPILER}" AND 
    DEFINED COMPILER_VERSION)
    set(DETECTED_COMPILER "${DETECTED_COMPILER}-${COMPILER_VERSION}")
  endif()
  
  # Set the output variable in the parent scope
  set(${OUTPUT_VARIABLE} "${DETECTED_COMPILER}" PARENT_SCOPE)
endfunction()