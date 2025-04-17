#
# Check sanitizers support across different compilers
#
function(check_sanitizers_support 
	SUPPORTS_UBSAN
	SUPPORTS_ASAN
)
	if ((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR
		CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*")
		AND NOT WIN32)
		set(${SUPPORTS_UBSAN} ON PARENT_SCOPE)
	else()
		set(${SUPPORTS_UBSAN} OFF PARENT_SCOPE)
	endif()

	if ((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR 
		CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*")
		AND WIN32)
		set(${SUPPORTS_ASAN} OFF PARENT_SCOPE)
	else ()
		set(${SUPPORTS_ASAN} ON PARENT_SCOPE)
	endif ()
endfunction()