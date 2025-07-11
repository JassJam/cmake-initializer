## This file should be placed in the root directory of your project.
## Then modify the CMakeLists.txt file in the root directory of your
## project to incorporate the testing dashboard.
##
## # The following are required to submit to the CDash dashboard:
##   ENABLE_TESTING()
##   INCLUDE(CTest)

set(CTEST_PROJECT_NAME "cmake-initializer")
set(CTEST_NIGHTLY_START_TIME "00:00:00 EST")

# Fallback default configuration (commented out)
# if(CMAKE_VERSION VERSION_GREATER 3.14)
#   set(CTEST_SUBMIT_URL https://my.cdash.org/submit.php?project=Boilerplate)
# else()
#   set(CTEST_DROP_METHOD "https")
#   set(CTEST_DROP_SITE "my.cdash.org")
#   set(CTEST_DROP_LOCATION "/submit.php?project=Boilerplate")
# endif()
# set(CTEST_DROP_SITE_CDASH TRUE)

# Configure testing timeout (in seconds) - can be overridden by preset
# set(CTEST_DROP_METHOD "https")  # Default to secure HTTPS
# set(CTEST_TEST_TIMEOUT 300)  # Default timeout of 5 minutes

# Note: Build name and upload configuration are handled by PresetConfiguration.cmake
