register_executable(HelloWorld_SharedLibrary_Program
    SOURCES
        src/main.cpp
    LINK_LIBS
        HelloWorld_SharedLibrary_Library
    NAMESPACE    ${THIS_PROJECT_NAMESPACE}
    EXPORT_SET   "${THIS_PROJECT_NAMESPACE}Targets"
)
