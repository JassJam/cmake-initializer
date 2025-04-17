add_library(HelloWorld_SharedLibrary_Library SHARED)

#

# load source files
file(GLOB SOURCE_FILES
	${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp
)

# load header files
file(GLOB HEADER_FILES
	${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp
)

#

# add source files
target_sources(HelloWorld_SharedLibrary_Library
    PRIVATE
        ${SOURCE_FILES}
)

# add header files
set_target_properties(HelloWorld_SharedLibrary_Library
    PROPERTIES
        PUBLIC_HEADER "${HEADER_FILES}"
)

# add include directories
target_include_directories(HelloWorld_SharedLibrary_Library
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/HelloWorld_SharedLibrary_Library>
)

# link dependencies
target_link_libraries(HelloWorld_SharedLibrary_Library
    PUBLIC
        ${THIS_PROJECT_NAMESPACE}::common
)

# install the component
install_component(
    HelloWorld_SharedLibrary_Library
    INCLUDE_SUBDIR HelloWorld_SharedLibrary_Library
    EXPORT_MACRO_NAME HELLOWORLD_EXPORT
)