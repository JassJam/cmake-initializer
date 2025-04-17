add_executable(HelloWorld_StaticLibrary_Program)

# add source files
target_sources(HelloWorld_StaticLibrary_Program
	PRIVATE
		src/main.cpp
)

# link dependencies 'HelloWorld_StaticLibrary_Library'
target_link_libraries(HelloWorld_StaticLibrary_Program
	PRIVATE
		HelloWorld_StaticLibrary_Library
)

# install the component
install_component(
	HelloWorld_StaticLibrary_Program
)
