include(${CMAKE_CURRENT_LIST_DIR}/Variables.cmake)

include(GNUInstallDirs)
include(GenerateExportHeader)

include(${CMAKE_CURRENT_LIST_DIR}/Options.cmake)

include(${CMAKE_CURRENT_LIST_DIR}/impl/Testing.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/impl/Toolchains.cmake)

include(${CMAKE_CURRENT_LIST_DIR}/impl/InstallComponent.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/impl/CPM.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/impl/CompilerCache.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/impl/ProjectBoilerplate.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/impl/PresetConfig.cmake)
