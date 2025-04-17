# Apache-2.0 license
#
# Source: github@xmake-io/xrepo-cmake

set(XMAKE_COMMIT_HASH "04bfe928266c65a65a738b57584d3e482e8e23d7")
set(XMAKE_CMAKE_DIR "${CMAKE_BINARY_DIR}/cmake")
set(XMAKE_CMAKE_URL "https://github.com/xmake-io/xrepo-cmake/raw/${XMAKE_COMMIT_HASH}/xrepo.cmake")
set(XMAKE_CMAKE_PATH "${XMAKE_CMAKE_DIR}/XMakePackageManager.cmake")

# Create directory if it doesn't exist
if (NOT EXISTS "${XMAKE_CMAKE_DIR}")
    file(MAKE_DIRECTORY "${XMAKE_CMAKE_DIR}")
endif()

# Download file if it doesn't exist or is outdated
if (NOT EXISTS "${XMAKE_CMAKE_PATH}")
    message(STATUS "Downloading XMakePackageManager.cmake from ${XMAKE_CMAKE_URL}")
    file(DOWNLOAD 
        "${XMAKE_CMAKE_URL}"
        "${XMAKE_CMAKE_PATH}"
        SHOW_PROGRESS
        STATUS download_status
        TLS_VERIFY ON
    )
    
    # Check download status
    list(GET download_status 0 status_code)
    list(GET download_status 1 status_message)
    if (NOT status_code EQUAL 0)
        message(FATAL_ERROR "Failed to download XMakePackageManager.cmake: ${status_message}")
    endif()
endif()

# Include the downloaded package manager
include("${XMAKE_CMAKE_PATH}")