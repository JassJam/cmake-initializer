include(CheckSanitizerSupport)
include(CMakeDependentOption)

#

check_sanitizers_support(
    SUPPORTS_UBSAN
    SUPPORTS_ASAN
)

#

#
# - PROJECT_ENABLE_HARDENING [ON*/OFF]: Enable sanitizers and hardening options
# - PROJECT_ENABLE_COVERAGE [ON/OFF*]: Enable coverage reporting
# - PROJECT_ENABLE_GLOBAL_HARDENING [ON*/OFF]: Attempt to push hardening options to built dependencies
# - PROJECT_PACKAGING_MAINTAINER_MODE [ON/OFF*]: Enable packaging maintainer mode (If enabled, ignores PROJECT_ENABLE_HARDENING)
# - PROJECT_ENABLE_IPO [ON*/OFF]: Enable IPO/LTO (Interprocedural Optimization / Link Time Optimization)
# - PROJECT_WARNINGS_AS_ERRORS [ON*/OFF]: Treat warnings as errors
# - PROJECT_ENABLE_SANITIZER_ADDRESS [ON*/OFF]: Enable address sanitizer
# - PROJECT_ENABLE_SANITIZER_LEAK [ON/OFF*]: Enable leak sanitizer
# - ENABLE_SANITIZER_UNDEFINED_BEHAVIOR [ON*/OFF]: Enable ub sanitizer
# - PROJECT_ENABLE_SANITIZER_THREAD [ON/OFF*]: Enable thread sanitizer
# - PROJECT_ENABLE_SANITIZER_MEMORY [ON/OFF*]: Enable memory sanitizer
# - PROJECT_ENABLE_UNITY_BUILD [ON/OFF*]: Enable unity builds
# - PROJECT_ENABLE_CLANG_TIDY [ON*/OFF]: Enable clang-tidy
# - PROJECT_ENABLE_CPPCHECK [ON*/OFF]: Enable cpp-check analysis
# - PROJECT_ENABLE_PCH [ON/OFF*]: Enable precompiled headers
# - PROJECT_ENABLE_CACHE [ON*/OFF]: Enable ccache
# - PROJECT_BUILD_FUZZ_TESTS [ON*/OFF]: Enable fuzz testing executable
#

option(PROJECT_ENABLE_HARDENING "Enable hardening" ON)
option(PROJECT_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
option(PROJECT_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ON)
option(PROJECT_ENABLE_COVERAGE "Enable coverage reporting" OFF)

if (NOT PROJECT_IS_TOP_LEVEL OR PROJECT_PACKAGING_MAINTAINER_MODE)
    option(PROJECT_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(PROJECT_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(PROJECT_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(PROJECT_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(ENABLE_SANITIZER_UNDEFINED_BEHAVIOR "Enable undefined behaviour sanitizer" OFF)
    option(PROJECT_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(PROJECT_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(PROJECT_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(PROJECT_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(PROJECT_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(PROJECT_ENABLE_PCH "Enable precompiled headers" OFF)
    option(PROJECT_ENABLE_CACHE "Enable ccache" OFF)
else ()
    option(PROJECT_ENABLE_IPO "Enable IPO/LTO" ON)
    option(PROJECT_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(PROJECT_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(PROJECT_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(ENABLE_SANITIZER_UNDEFINED_BEHAVIOR "Enable undefined behaviour sanitizer" ${SUPPORTS_UBSAN})
    option(PROJECT_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(PROJECT_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(PROJECT_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(PROJECT_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(PROJECT_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(PROJECT_ENABLE_PCH "Enable precompiled headers" OFF)
    option(PROJECT_ENABLE_CACHE "Enable ccache" ON)
endif ()

if (NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
        PROJECT_ENABLE_IPO
        PROJECT_WARNINGS_AS_ERRORS
        PROJECT_ENABLE_SANITIZER_ADDRESS
        PROJECT_ENABLE_SANITIZER_LEAK
        ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
        PROJECT_ENABLE_SANITIZER_THREAD
        PROJECT_ENABLE_SANITIZER_MEMORY
        PROJECT_ENABLE_UNITY_BUILD
        PROJECT_ENABLE_CLANG_TIDY
        PROJECT_ENABLE_CPPCHECK
        PROJECT_ENABLE_COVERAGE
        PROJECT_ENABLE_PCH
        PROJECT_ENABLE_CACHE)
endif ()

#

cmake_dependent_option(
    PROJECT_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    PROJECT_ENABLE_HARDENING
    OFF
)
