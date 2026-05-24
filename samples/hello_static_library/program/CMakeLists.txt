register_executable(HelloWorld_StaticLibrary_Program
    SOURCES
        src/main.cpp
    LINK_LIBS
        HelloWorld_StaticLibrary_Library
    NAMESPACE    ${THIS_PROJECT_NAMESPACE}
    EXPORT_SET   "${THIS_PROJECT_NAMESPACE}Targets"
)
