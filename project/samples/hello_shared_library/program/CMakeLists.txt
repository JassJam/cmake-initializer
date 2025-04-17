add_executable(HelloWorld_SharedLibrary_Program)

# add source files
target_sources(HelloWorld_SharedLibrary_Program
	PRIVATE
		src/main.cpp
)

# link dependencies 'HelloWorld_SharedLibrary_Library'
target_link_libraries(HelloWorld_SharedLibrary_Program
	PRIVATE
		HelloWorld_SharedLibrary_Library
)

# install the component
install_component(
	HelloWorld_SharedLibrary_Program
)