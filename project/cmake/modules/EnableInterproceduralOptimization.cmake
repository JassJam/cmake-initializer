include(CheckIPOSupported)

check_ipo_supported(RESULT result OUTPUT output)

if (result)
  set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
  message(STATUS "IPO is supported: ${output}")
else ()
  message(SEND_ERROR "IPO is not supported: ${output}")
endif ()
