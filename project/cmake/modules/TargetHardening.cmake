include(GetCurrentCompiler)

#
# Enable hardening flags for the project
# - TARGETS[in] <target ...> The target to apply the hardening options to
# - FOR_ALL_DEPENDENCIES[in], apply the hardening options to all dependencies of the target
#
# Example usage:
# targets_enable_hardering(
# 	TARGETS Target1 Target2
# 	FOR_ALL_DEPENDENCIES TRUE
# )
#
function(targets_enable_hardering)
	set(options
		FOR_ALL_DEPENDENCIES
	)
	set(multiValueArgs
		TARGETS
	)
	cmake_parse_arguments(
		ARG
		${options}
		""
		${multiValueArgs}
		${ARGN}
	)

	if (ARG_FOR_ALL_DEPENDENCIES)
		message(STATUS "** Enable hardening for targets with all dependencies: ${ARG_TARGETS}")
	else ()
		message(STATUS "** Enable hardening for targets: ${ARG_TARGETS}")
	endif ()

    if (NOT SUPPORTS_UBSAN 
         OR PROJECT_ENABLE_SANITIZER_UNDEFINED
         OR PROJECT_ENABLE_SANITIZER_ADDRESS
         OR PROJECT_ENABLE_SANITIZER_THREAD
         OR PROJECT_ENABLE_SANITIZER_LEAK)
        set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else ()
        set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif ()

	get_current_compiler(
		CURRENT_COMPILER
	)
	
	set(NEW_LINK_OPTIONS "")
	set(NEW_COMPILE_OPTIONS "")
	set(NEW_CXX_DEFINITIONS "")

	if ("${CURRENT_COMPILER}" STREQUAL "MSVC")
		message(STATUS "*** Hardening MSVC flags: /DYNAMICBASE /guard:cf /NXCOMPAT /CETCOMPAT")
		list(APPEND NEW_COMPILE_OPTIONS /DYNAMICBASE /guard:cf)
		list(APPEND NEW_LINK_OPTIONS /NXCOMPAT /CETCOMPAT)

	elseif ("${CURRENT_COMPILER}" MATCHES "Clang|GCC")
		message(STATUS "*** GLIBC++ Assertions (vector[], string[], ...) enabled")
		list(APPEND NEW_CXX_DEFINITIONS -D_GLIBCXX_DEBUG -D_GLIBCXX_DEBUG_PEDANTIC -D_GLIBCXX_ASSERTIONS)

		message(STATUS "*** g++/clang _FORTIFY_SOURCE=3 enabled")
		list(APPEND NEW_COMPILE_OPTIONS -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3)

		#

		check_cxx_compiler_flag(-fstack-protector-strong STACK_PROTECTOR)
		if (STACK_PROTECTOR)
			message(STATUS "*** g++/clang -fstack-protector-strong enabled")
			set(NEW_COMPILE_OPTIONS "${NEW_COMPILE_OPTIONS} -fstack-protector-strong")
		else ()
			message(STATUS "*** g++/clang -fstack-protector-strong NOT enabled (not supported)")
		endif ()

		#

		check_cxx_compiler_flag(-fcf-protection CF_PROTECTION)
		if (CF_PROTECTION)
			message(STATUS "*** g++/clang -fcf-protection enabled")
			set(NEW_COMPILE_OPTIONS "${NEW_COMPILE_OPTIONS} -fcf-protection")
		else ()
			message(STATUS "*** g++/clang -fcf-protection NOT enabled (not supported)")
		endif ()

		#

		check_cxx_compiler_flag(-fstack-clash-protection CLASH_PROTECTION)
		if (CLASH_PROTECTION)
		  if (LINUX OR "${CURRENT_COMPILER}" MATCHES "GCC")
			message(STATUS "*** g++/clang -fstack-clash-protection enabled")
			set(NEW_COMPILE_OPTIONS "${NEW_COMPILE_OPTIONS} -fstack-clash-protection")
		  else ()
			message(STATUS "*** g++/clang -fstack-clash-protection NOT enabled (clang on non-Linux)")
		  endif ()
		else ()
		  message(STATUS "*** g++/clang -fstack-clash-protection NOT enabled (not supported)")
		endif ()

		#

		check_cxx_compiler_flag("-fsanitize=undefined -fno-sanitize-recover=undefined -fsanitize-minimal-runtime"
								MINIMAL_RUNTIME)

		if (MINIMAL_RUNTIME)
			list(APPEND NEW_COMPILE_OPTIONS -fsanitize=undefined -fsanitize-minimal-runtime)
			list(APPEND NEW_LINK_OPTIONS -fsanitize=undefined -fsanitize-minimal-runtime)
			if (NOT ARG_FOR_ALL_DEPENDENCIES)
				list(APPEND NEW_COMPILE_OPTIONS -fno-sanitize-recover=undefined)
				list(APPEND NEW_LINK_OPTIONS -fno-sanitize-recover=undefined)
			else ()
				message(STATUS "** not enabling -fno-sanitize-recover=undefined for global consumption")
			endif()
			message(STATUS "*** ubsan minimal runtime enabled")
		else ()
			message(STATUS "*** ubsan minimal runtime NOT enabled (not supported)")
		endif ()
	else ()
		message(STATUS "*** ubsan minimal runtime NOT enabled (not requested)")
	endif ()
	
	message(STATUS "** Hardening Compiler Flags: ${NEW_COMPILE_OPTIONS}")
	message(STATUS "** Hardening Linker Flags: ${NEW_LINK_OPTIONS}")
	message(STATUS "** Hardening Compiler Defines: ${NEW_CXX_DEFINITIONS}")
	
	if (ARG_FOR_ALL_DEPENDENCIES)
		message(STATUS "** Setting hardening options globally for all dependencies")
		list(APPEND CMAKE_CXX_FLAGS "${NEW_COMPILE_OPTIONS}")
		list(APPEND CMAKE_EXE_LINKER_FLAGS "${NEW_LINK_OPTIONS}")
		list(APPEND CMAKE_CXX_DEFINITIONS "${NEW_CXX_DEFINITIONS}")
	else()
		foreach(target ${ARG_TARGETS})
			if (NOT TARGET ${target})
				message(FATAL_ERROR "Target ${target} not found")
			endif()
			# if NEW_COMPILE_OPTIONS is not empty, set it
			if (NOT "${NEW_COMPILE_OPTIONS}" STREQUAL "")
				target_compile_options(${target} INTERFACE ${NEW_COMPILE_OPTIONS})
				set_target_properties(${target} PROPERTIES COMPILE_FLAGS "${NEW_COMPILE_OPTIONS}")
			endif()
			# if NEW_LINK_OPTIONS is not empty, set it
			if (NOT "${NEW_LINK_OPTIONS}" STREQUAL "")
				target_link_options(${target} INTERFACE ${NEW_LINK_OPTIONS})
			endif()
			# if NEW_CXX_DEFINITIONS is not empty, set it
			if (NOT "${NEW_CXX_DEFINITIONS}" STREQUAL "")
				target_compile_definitions(${target} INTERFACE ${NEW_CXX_DEFINITIONS})
			endif()
		endforeach()
	endif()
endfunction()