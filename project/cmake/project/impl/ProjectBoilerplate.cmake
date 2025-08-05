include(LinkDependencies)
include(InstallComponent)

include(${CMAKE_CURRENT_LIST_DIR}/boilerplate/RegisterExecutable.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/boilerplate/RegisterLibrary.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/boilerplate/RegisterEmscripten.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/boilerplate/RegisterProject.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/boilerplate/RegisterTest.cmake)
