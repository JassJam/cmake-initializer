
register_test(MathUtilsTests
    SOURCES
        test_doctest.cpp
    LINK_LIBS
        PRIVATE MathUtils
    COMPILE_DEFINITIONS PRIVATE DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
)

if(COMMAND CPMAddPackage)
    CPMAddPackage(
            NAME doctest
            GITHUB_REPOSITORY doctest/doctest
            GIT_TAG v2.5.2
            SYSTEM ON
    )
    target_link_dependencies(MathUtilsTests
        PRIVATE
        doctest::doctest
    )
elseif(COMMAND xrepo_package)
    xrepo_package("doctest 2.5.2")
    xrepo_target_packages(MathUtilsTests doctest)
else ()
    message(FATAL_ERROR "No package manager available for doctest.")
endif ()
