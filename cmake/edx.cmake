# --------------------------------
# EDX File Format Library
# --------------------------------
MESSAGE(STATUS "=================================================")
MESSAGE(STATUS "Generating edX File Format Library (edx)")

SET (PROJECT_CONFIG_FILES
	${CMAKE_SOURCE_DIR}/.clang-format
	${CMAKE_SOURCE_DIR}/.editorconfig
	${CMAKE_SOURCE_DIR}/edX/config/resource.h
	${CMAKE_SOURCE_DIR}/edX/config/edXConfig.h
)
FILE(GLOB EDX_HEADER_DIR
	${CMAKE_SOURCE_DIR}/edX/include
)
FILE(GLOB EDX_HEADER_FILES
    ${CMAKE_SOURCE_DIR}/edX/include/*
)
FILE(GLOB EDX_SOURCE_DIR
    ${CMAKE_SOURCE_DIR}/edX/src
)
FILE(GLOB EDX_SOURCE_FILES
    ${CMAKE_SOURCE_DIR}/edX/src/*
)
FILE(GLOB EDX_DOCUMENTATION_FILES
	${CMAKE_SOURCE_DIR}/docs/*
)
SET(EDX_PLATFORM_SOURCES)
IF(WIN32)
    LIST(APPEND EDX_PLATFORM_SOURCES ${CMAKE_SOURCE_DIR}/edX/config/edX.rc)
ENDIF()

ADD_LIBRARY(edX
	SHARED
    ${EDX_SOURCE_FILES}
    ${EDX_HEADER_FILES}
	${PROJECT_CONFIG_FILES}
	${EDX_DOCUMENTATION_FILES}
    ${EDX_PLATFORM_SOURCES}
)

# Use project-wide C++20 standard (required for <format> etc.)
SET_TARGET_PROPERTIES(edX PROPERTIES CXX_STANDARD 20 CXX_STANDARD_REQUIRED YES)

# Optional: Build example executable
OPTION(EDX_BUILD_EXAMPLES "Build edX format examples" OFF)
IF(EDX_BUILD_EXAMPLES)
    ADD_EXECUTABLE(edXExample ${EDX_EXAMPLE_FILES})
    TARGET_LINK_LIBRARIES(edXExample PRIVATE edX)
    TARGET_COMPILE_FEATURES(edXExample PRIVATE cxx_std_20)
ENDIF()

# Source groups for IDE organization
SOURCE_GROUP("API"
	FILES
	    ${EDX_HEADER_DIR}/edXManager.h
)

SOURCE_GROUP("Project Format"
	FILES
	    ${EDX_HEADER_DIR}/edXProjectFile.h
	    ${EDX_SOURCE_DIR}/edXProjectFile.cpp
	    ${EDX_SOURCE_DIR}/edXWriter.cpp
	    ${EDX_SOURCE_DIR}/edXReader.cpp
)

SOURCE_GROUP("Library Format"
	FILES
	    ${EDX_HEADER_DIR}/edXLibraryFile.h
	    ${EDX_SOURCE_DIR}/edXLibraryFile.cpp
	    ${EDX_SOURCE_DIR}/edXLibraryWriter.cpp
	    ${EDX_SOURCE_DIR}/edXLibraryReader.cpp
)

SOURCE_GROUP("Utilities"
	FILES
	    ${EDX_HEADER_DIR}/edXTimeUtils.h
	    ${EDX_SOURCE_DIR}/edXTimeUtils.cpp
)

SOURCE_GROUP("Examples"
	FILES
	    ${EDX_SOURCE_DIR}/edXExample.cpp
)

SOURCE_GROUP("Documentation"
	FILES
	${EDX_DOCUMENTATION_FILES}
)

SOURCE_GROUP("Resource"
	FILES
		${PROJECT_CONFIG_FILES}
		${EDX_PLATFORM_SOURCES}
)

TARGET_COMPILE_DEFINITIONS(edX
	PRIVATE
		UNICODE
		_UNICODE
		$<$<PLATFORM_ID:Windows>:_CRT_SECURE_NO_WARNINGS>
		$<$<CONFIG:Debug>:_CONSOLE>
		$<$<CONFIG:Debug>:_DEBUG>
		$<$<CONFIG:Debug>:EDX_DEBUG>
		$<$<CONFIG:Release>:EDX_RELEASE>
		EDX_EXPORTS  # Define this when building the DLL
)

TARGET_INCLUDE_DIRECTORIES(edX
	PUBLIC
		${CMAKE_SOURCE_DIR}/edX/include
	PRIVATE
		${CMAKE_SOURCE_DIR}
		${CMAKE_SOURCE_DIR}/edX/src
)

TARGET_LINK_LIBRARIES(edX PRIVATE
	nlohmann_json::nlohmann_json
)

# Link XPSceneryLib only if it exists (optional dependency)
IF (TARGET XPSceneryLib::XPSceneryLib)
    TARGET_COMPILE_DEFINITIONS(edX PRIVATE HAVE_XPLIB)
    TARGET_INCLUDE_DIRECTORIES(edX PRIVATE
      $<TARGET_PROPERTY:XPSceneryLib::XPSceneryLib,INTERFACE_INCLUDE_DIRECTORIES>
    )
ELSEIF(TARGET XPSceneryLib)
    TARGET_COMPILE_DEFINITIONS(edX PRIVATE HAVE_XPLIB)
    TARGET_INCLUDE_DIRECTORIES(edX PRIVATE
      $<TARGET_PROPERTY:XPSceneryLib,INTERFACE_INCLUDE_DIRECTORIES>
    )
ELSE()
    MESSAGE(STATUS "XPSceneryLib not found; building edX without X-Plane Scenery integration")
ENDIF()

# Ensure consistent UTF-8 source decoding on MSVC (prevents fmt / Unicode warnings)
IF (MSVC)
	TARGET_COMPILE_OPTIONS(edX PRIVATE /utf-8)
ENDIF()

# Set output directory
SET_TARGET_PROPERTIES(edX PROPERTIES
    OUTPUT_NAME "edX"
	RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin/${CMAKE_CFG_INTDIR}/${EDX_OUTPUT_OS_NAME}
	LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin/${CMAKE_CFG_INTDIR}/${EDX_OUTPUT_OS_NAME}
	ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin/${CMAKE_CFG_INTDIR}/${EDX_OUTPUT_OS_NAME}
	VERSION ${PROJECT_VERSION}
	SOVERSION ${PROJECT_VERSION_MAJOR}
)

# On Linux, drop the default 'lib' prefix so the file is named exactly 'edX.so'
IF(UNIX AND NOT APPLE)
	SET_TARGET_PROPERTIES(edX PROPERTIES PREFIX "")
ENDIF()

# --------------------------------

IF (WIN32 AND TARGET edX AND NOT EDX_INCREMENT_VERSION_ON_CONFIG AND NOT EDX_CI_MODE)
	# We want to bump only when the shared library is actually built:
	# - For VS/Xcode: use PRE_LINK so the new version is embedded in the artifact
	# - For Makefiles/Ninja: use POST_BUILD (runs only when linking occurs); acceptable since
	#   resource.h is Windows-specific and doesn't embed on non-Windows builds anyway.

	FIND_PACKAGE(Python3 COMPONENTS Interpreter QUIET)

	# Script path (case-insensitive handling)
	SET(_EDX_VER_SCRIPT_1 ${CMAKE_SOURCE_DIR}/scripts/increment_edX_build.py)
	SET(_EDX_VER_SCRIPT_2 ${CMAKE_SOURCE_DIR}/scripts/increment_edx_build.py)
	IF(EXISTS "${_EDX_VER_SCRIPT_1}")
		SET(EDX_VERSION_SCRIPT ${_EDX_VER_SCRIPT_1})
	ELSEIF(EXISTS "${_EDX_VER_SCRIPT_2}")
		SET(EDX_VERSION_SCRIPT ${_EDX_VER_SCRIPT_2})
	ENDIF()

	IF(Python3_Interpreter_FOUND AND EDX_VERSION_SCRIPT)
		if(CMAKE_GENERATOR MATCHES "Visual Studio|Xcode")
			ADD_CUSTOM_COMMAND(
				TARGET edX
				PRE_LINK
				COMMAND ${Python3_EXECUTABLE} ${EDX_VERSION_SCRIPT}
				WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
				COMMENT "Incrementing edX build number (resource.h) before linking edX"
				VERBATIM
			)
		else()
			ADD_CUSTOM_COMMAND(
				TARGET edX
				POST_BUILD
				COMMAND ${Python3_EXECUTABLE} ${EDX_VERSION_SCRIPT}
				WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
				COMMENT "Incrementing edX build number (resource.h) after building edX"
				VERBATIM
			)
		endif()
	ELSE()
		MESSAGE(STATUS "Skipping library-only version increment: Python or script not found.")
	ENDIF()
ELSEIF(WIN32 AND EDX_INCREMENT_VERSION_ON_CONFIG AND NOT EDX_CI_MODE)
	MESSAGE(STATUS "Configure-time version increment is enabled; skipping build-time increment to avoid double bump.")
ENDIF()

