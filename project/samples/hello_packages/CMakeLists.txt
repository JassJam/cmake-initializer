add_executable(HelloPackages)

# add dependencies
include(Dependencies.cmake)
target_load_dependencies(HelloPackages)

# add source files
target_sources(HelloPackages
	PRIVATE
		src/main.cpp
)

# add include directories
target_include_directories(HelloPackages
	PRIVATE
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

# link libraries
target_link_libraries(HelloPackages
	PRIVATE
		${THIS_PROJECT_NAMESPACE}::common
)

# install the component
install_component(
	HelloPackages
)