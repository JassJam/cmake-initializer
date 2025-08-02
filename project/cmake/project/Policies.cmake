# MSVC runtime library flags are selected by an abstraction
if(POLICY CMP0091)
    cmake_policy(SET CMP0091 NEW)
endif()

# MSVC warning flags are not in CMAKE_<LANG>_FLAGS by default
if(POLICY CMP0092)
    cmake_policy(SET CMP0092 NEW) 
endif()

# MSVC RTTI flag warning
if(POLICY CMP0117)
    cmake_policy(SET CMP0117 NEW) 
endif()

# Set policy for IN_LIST operator
if(POLICY CMP0057)
    cmake_policy(SET CMP0057 NEW)
endif()