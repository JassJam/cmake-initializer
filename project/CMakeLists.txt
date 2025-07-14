cmake_minimum_required(VERSION 3.21)

message(STATUS "CMake version: ${CMAKE_VERSION}")
message(STATUS "Using C++ standard: ${CMAKE_CXX_STANDARD}")

include(./cmake/Policies.cmake)
include(./ProjectMetadata.cmake)

# Add our cmake modules early for EMSDK setup
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)
include(EmsdkManager)


# Set up project with metadata
project(${THIS_PROJECT_NAME}
    VERSION "${THIS_PROJECT_VERSION}"
    DESCRIPTION ${THIS_PROJECT_DESCRIPTION}
    LANGUAGES CXX
    HOMEPAGE_URL ${THIS_PROJECT_HOMEPAGE_URL}
)

message(STATUS "Configuring ${THIS_PROJECT_PRETTY_NAME} v${THIS_PROJECT_VERSION}")

# Basic setup
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)  # Generate compile_commands.json

include(GNUInstallDirs)
include(GenerateExportHeader)

# Enable testing
if(BUILD_TESTING)
    include(CTest)
    enable_testing()
endif()

# Add remaining cmake modules
include(PreventInSourceBuilds)
include(InstallComponent)
include(CPMPackageManager)
include(CPMDownloader)
include(ProjectBoilerplate)
include(CompilerCache)
include(./PresetConfig.cmake)

#

include(Projects.cmake)
