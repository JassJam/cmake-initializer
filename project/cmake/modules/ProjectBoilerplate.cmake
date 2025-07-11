# ==============================================================================
# Project Boilerplate - Modular CMake Functions
# ==============================================================================
# This file includes all modular components for the CMake project boilerplate
# system. Each module provides specific functionality for different target types.

# Include modular components
include(${CMAKE_CURRENT_LIST_DIR}/RegisterExecutable.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/RegisterLibrary.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/RegisterProject.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/RegisterTest.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/PresetConfiguration.cmake)
