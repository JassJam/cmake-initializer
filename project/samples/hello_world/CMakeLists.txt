add_executable(HelloWorld)

# add source files
target_sources(HelloWorld
	PRIVATE
		src/main.cpp
)

# add include directories
target_include_directories(HelloWorld
	PRIVATE
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

# link libraries
target_link_libraries(HelloWorld
	PRIVATE
		${THIS_PROJECT_NAMESPACE}::common
)

# install the component
install_component(
	HelloWorld
)