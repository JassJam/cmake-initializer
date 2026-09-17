include_guard(DIRECTORY)

if("CPM" IN_LIST PACKAGE_MANAGERS)
    message(STATUS "Enabling CPM package manager")
    include(${CMAKE_CURRENT_LIST_DIR}/package-managers/CPM.cmake)
endif()

if("XMake" IN_LIST PACKAGE_MANAGERS)
    message(STATUS "Enabling XMake package manager")
    include(${CMAKE_CURRENT_LIST_DIR}/package-managers/XMake.cmake)
endif()

if("XCMake" IN_LIST PACKAGE_MANAGERS)
    message(STATUS "Enabling XCMake package manager")
    include(${CMAKE_CURRENT_LIST_DIR}/package-managers/XCMake.cmake)
endif()

if("SPM" IN_LIST PACKAGE_MANAGERS)
    message(STATUS "Enabling XCMake package manager")
    include(${CMAKE_CURRENT_LIST_DIR}/package-managers/spm.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/package-managers/spm-yaml.cmake)
endif()
