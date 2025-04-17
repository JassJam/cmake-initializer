cmake_minimum_required(VERSION 3.30)

# Only set the cxx_standard if it is not set by someone else
if (NOT DEFINED CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
endif()

message(STATUS "CMake version: ${CMAKE_VERSION}")
message(STATUS "Using C++ standard: ${CMAKE_CXX_STANDARD}")

# Disable C++ extensions for better portability
set(CMAKE_CXX_EXTENSIONS OFF)
include(./ProjectMetadata.cmake)

project(
	${THIS_PROJECT_NAME}
	VERSION "${THIS_PROJECT_VERSION}"
	DESCRIPTION ${THIS_PROJECT_DESCRIPTION}
	LANGUAGES CXX
	HOMEPAGE_URL ${THIS_PROJECT_HOMEPAGE_URL}
)

message(STATUS "Configuring ${THIS_PROJECT_PRETTY_NAME} (${THIS_PROJECT_NAME})...")

include(GNUInstallDirs)
include(GenerateExportHeader)

#

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)
include(PreventInSourceBuilds)
include(InstallComponent)
include(CPMPackageManager)
include(CPMDownloader)

#

include(Projects.cmake)
