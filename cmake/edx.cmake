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
	${CMAKE_SOURCE_DIR}/edX/includes
)
FILE(GLOB EDX_HEADER_FILES
    ${CMAKE_SOURCE_DIR}/edX/includes/*
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
		_CRT_SECURE_NO_WARNINGS
		$<$<CONFIG:Debug>:_CONSOLE>
		$<$<CONFIG:Debug>:_DEBUG>
		$<$<CONFIG:Debug>:EDX_DEBUG>
		$<$<CONFIG:Release>:EDX_RELEASE>
        EDX_EXPORTS  # Define this when building the DLL
)

TARGET_INCLUDE_DIRECTORIES(edX
	PUBLIC
		${CMAKE_SOURCE_DIR}/edX/includes
	PRIVATE
		${CMAKE_SOURCE_DIR}
		${CMAKE_SOURCE_DIR}/edX/src
)

TARGET_LINK_LIBRARIES(edX PRIVATE
	nlohmann_json::nlohmann_json
)

# Ensure consistent UTF-8 source decoding on MSVC (prevents fmt / Unicode warnings)
IF (MSVC)
	TARGET_COMPILE_OPTIONS(edX PRIVATE /utf-8)
ENDIF()

# Set output directory
SET_TARGET_PROPERTIES(edX PROPERTIES
    OUTPUT_NAME "edX"
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
    ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)

# --------------------------------

IF (WIN32)
    FIND_PACKAGE(Python3 COMPONENTS Interpreter REQUIRED)

    # Script path
    SET(EDX_VERSION_SCRIPT ${CMAKE_SOURCE_DIR}/scripts/increment_edX_build.py)

    IF (MSVC)
        # PRE_BUILD supported by Visual Studio
        ADD_CUSTOM_COMMAND(
            TARGET edX
            PRE_BUILD
            COMMAND ${Python3_EXECUTABLE} ${EDX_VERSION_SCRIPT}
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            COMMENT "Incrementing edX build number (resource.h)"
            VERBATIM
        )
    ELSE()
        # Fallback for other Windows generators
        ADD_CUSTOM_TARGET(IncrementedXVersion
            COMMAND ${Python3_EXECUTABLE} ${EDX_VERSION_SCRIPT}
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            COMMENT "Incrementing edX build number (resource.h)"
            VERBATIM
            BYPRODUCTS ${CMAKE_SOURCE_DIR}/edX/config/resource.h
        )
        ADD_DEPENDENCIES(edX IncrementedXVersion)
    ENDIF()
ENDIF()

