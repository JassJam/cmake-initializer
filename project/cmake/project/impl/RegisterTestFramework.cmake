# Global variables to store test framework configuration
set_property(GLOBAL PROPERTY TEST_FRAMEWORK_REGISTERED FALSE)
set_property(GLOBAL PROPERTY TEST_FRAMEWORK_NAME "")
set_property(GLOBAL PROPERTY TEST_FRAMEWORK_LIBRARIES "")
set_property(GLOBAL PROPERTY TEST_FRAMEWORK_PACKAGE_MANAGER "")

#
# usage:
# register_test_framework("doctest") (or "catch2", "gtest", "boost")
#
function(register_test_framework FRAMEWORK_NAME)
    # Skip if testing is disabled
    if (NOT BUILD_TESTING)
        message(STATUS "Testing disabled, skipping test framework registration")
        return()
    endif ()

    get_property(already_registered GLOBAL PROPERTY TEST_FRAMEWORK_REGISTERED)
    if (already_registered)
        message(WARNING "Test framework already registered. Skipping duplicate registration.")
        return()
    endif ()

    message(STATUS "Registering test framework: ${FRAMEWORK_NAME}")

    # Set up framework-specific configuration
    if (FRAMEWORK_NAME STREQUAL "doctest")
        if (COMMAND CPMAddPackage)
            CPMAddPackage(
                    NAME doctest
                    GITHUB_REPOSITORY doctest/doctest
                    GIT_TAG v${DOCTEST_VERSION}
                    SYSTEM ON
            )
            set(FRAMEWORK_LIBS doctest::doctest)
            set(FRAMEWORK_DEFS "DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN")
            set(FRAMEWORK_PACKAGE_MANAGER "CPM")
            
        elseif (COMMAND xrepo_package)
            xrepo_package("doctest ${DOCTEST_VERSION}")
            set(FRAMEWORK_LIBS doctest::doctest)
            set(FRAMEWORK_DEFS "DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN")
            set(FRAMEWORK_PACKAGE_MANAGER "XMake")
            
        else ()
            message(WARNING "No package manager available for doctest.")
        endif ()

    elseif (FRAMEWORK_NAME STREQUAL "catch2")
        if (COMMAND CPMAddPackage)
            CPMAddPackage(
                    NAME Catch2
                    GITHUB_REPOSITORY catchorg/Catch2
                    GIT_TAG v${CATCH2_VERSION}
                    SYSTEM ON
            )
            set(FRAMEWORK_LIBS Catch2::Catch2WithMain)
            set(FRAMEWORK_DEFS "")
            set(FRAMEWORK_PACKAGE_MANAGER "CPM")
            
        elseif (COMMAND xrepo_package)
            xrepo_package("catch2 ${CATCH2_VERSION}")
            set(FRAMEWORK_LIBS Catch2::Catch2WithMain)
            set(FRAMEWORK_DEFS "")
            set(FRAMEWORK_PACKAGE_MANAGER "XMake")
            
        else ()
            message(WARNING "No package manager available for Catch2.")
        endif ()

    elseif (FRAMEWORK_NAME STREQUAL "gtest")
        if (COMMAND CPMAddPackage)
            CPMAddPackage(
                    NAME googletest
                    GITHUB_REPOSITORY google/googletest
                    GIT_TAG v${GTEST_VERSION}
                    SYSTEM ON
            )
            set(FRAMEWORK_LIBS gtest_main)
            set(FRAMEWORK_DEFS "")
            set(FRAMEWORK_PACKAGE_MANAGER "CPM")
            
        elseif (COMMAND xrepo_package)
            xrepo_package("gtest ${GTEST_VERSION}")
            set(FRAMEWORK_LIBS gtest_main)
            set(FRAMEWORK_DEFS "")
            set(FRAMEWORK_PACKAGE_MANAGER "XMake")
            
        else ()
            message(WARNING "No package manager available for Google Test.")
        endif ()

    elseif (FRAMEWORK_NAME STREQUAL "boost")
        if (COMMAND CPMAddPackage)
            CPMAddPackage(
                    NAME boost
                    GITHUB_REPOSITORY boostorg/boost
                    GIT_TAG ${BOOST_VERSION}
                    OPTIONS
                    "BOOST_ENABLE_CMAKE ON"
                    "BOOST_INCLUDE_LIBRARIES test"
                    SYSTEM ON
            )
            set(FRAMEWORK_LIBS Boost::unit_test_framework)
            set(FRAMEWORK_DEFS "BOOST_TEST_MODULE=Tests")
            set(FRAMEWORK_PACKAGE_MANAGER "CPM")
            
        elseif (COMMAND xrepo_package)
            xrepo_package("boost")
            set(FRAMEWORK_LIBS Boost::unit_test_framework)
            set(FRAMEWORK_DEFS "BOOST_TEST_MODULE=Tests")
            set(FRAMEWORK_PACKAGE_MANAGER "XMake")
            
        else ()
            message(WARNING "No package manager available for Boost Test.")
        endif ()

    else ()
        message(WARNING "Unknown test framework: ${FRAMEWORK_NAME}. Supported: doctest, catch2, gtest, boost")
    endif ()

    # Store configuration globally
    set_property(GLOBAL PROPERTY TEST_FRAMEWORK_REGISTERED TRUE)
    set_property(GLOBAL PROPERTY TEST_FRAMEWORK_NAME "${FRAMEWORK_NAME}")
    set_property(GLOBAL PROPERTY TEST_FRAMEWORK_LIBRARIES "${FRAMEWORK_LIBS}")
    set_property(GLOBAL PROPERTY TEST_FRAMEWORK_DEFINITIONS "${FRAMEWORK_DEFS}")
    set_property(GLOBAL PROPERTY TEST_FRAMEWORK_PACKAGE_MANAGER "${FRAMEWORK_PACKAGE_MANAGER}")

    message(STATUS "Test framework '${FRAMEWORK_NAME}' registered successfully")
endfunction()

#
# function to manually register a test framework with custom settings
#
# usage:
# register_test_framework_manual(name
#   [LIBRARIES libs...]   # Libraries to link against
#   [DEFINITIONS defs...] # Preprocessor definitions
# )
#
function(register_test_framework_manual FRAMEWORK_NAME)
    # Skip if testing is disabled
    if (NOT BUILD_TESTING)
        message(STATUS "Testing disabled, skipping test framework registration")
        return()
    endif ()

    get_property(already_registered GLOBAL PROPERTY TEST_FRAMEWORK_REGISTERED)
    if (already_registered)
        message(WARNING "Test framework already registered. Skipping duplicate registration.")
        return()
    endif ()

    set(options "")
    set(oneValueArgs NAME)
    set(multiValueArgs LIBRARIES DEFINITIONS PACKAGE_MANAGER)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    #

    set_property(GLOBAL PROPERTY TEST_FRAMEWORK_REGISTERED TRUE)
    set_property(GLOBAL PROPERTY TEST_FRAMEWORK_NAME "${ARG_NAME}")
    set_property(GLOBAL PROPERTY TEST_FRAMEWORK_LIBRARIES "${ARG_LIBRARIES}")
    set_property(GLOBAL PROPERTY TEST_FRAMEWORK_DEFINITIONS "${ARG_DEFINITIONS}")
    set_property(GLOBAL PROPERTY TEST_FRAMEWORK_PACKAGE_MANAGER "${ARG_PACKAGE_MANAGER}")

    message(STATUS "Test framework '${ARG_NAME}' registered successfully")
endfunction()
