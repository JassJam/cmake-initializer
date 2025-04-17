add_library(HelloWorld_StaticLibrary_Library STATIC)


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
target_sources(HelloWorld_StaticLibrary_Library
    PRIVATE
        ${SOURCE_FILES}
)

# add header files
set_target_properties(HelloWorld_StaticLibrary_Library
    PROPERTIES
        PUBLIC_HEADER "${HEADER_FILES}"
)

# add include directories
target_include_directories(HelloWorld_StaticLibrary_Library
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/HelloWorld_StaticLibrary_Library>
)

# link libraries
target_link_libraries(HelloWorld_StaticLibrary_Library
    PUBLIC
        ${THIS_PROJECT_NAMESPACE}::common
)

# install the component
install_component(
    HelloWorld_StaticLibrary_Library
    INCLUDE_SUBDIR HelloWorld_StaticLibrary_Library
)