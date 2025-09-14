CMAKE_MINIMUM_REQUIRED(VERSION 3.8...4.0)

# --------------------------------
# Global Setup
# --------------------------------
# Early top-level detection (works before project())
SET(EDXLIB_TOPLEVEL_EARLY OFF)
IF(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
	SET(EDXLIB_TOPLEVEL_EARLY ON)
ENDIF()

# Only set a toolchain if none is provided (don’t override parent)
IF(NOT DEFINED CMAKE_TOOLCHAIN_FILE AND EDXLIB_TOPLEVEL_EARLY)
	IF(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/dependency/vcpkg/scripts/buildsystems/vcpkg.cmake")
		SET(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/dependency/vcpkg/scripts/buildsystems/vcpkg.cmake" CACHE STRING "" FORCE)
	ENDIF()
ENDIF()

SET(CMAKE_CONFIGURATION_TYPES Debug Release CACHE STRING INTERNAL FORCE)
SET(CMAKE_SUPPRESS_DEVELOPER_WARNINGS 1 CACHE INTERNAL "No dev warnings")
SET(VCPKG_INSTALL_OPTIONS --no-print-usage)
SET_PROPERTY(GLOBAL PROPERTY USE_FOLDERS ON)
LIST(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

SET(BIN_DIR ${CMAKE_SOURCE_DIR}/bin/${CMAKE_CFG_INTDIR})

# --------------------------------
# BUILD SYSTEM
# --------------------------------
SET(CMAKE_CXX_STANDARD 20)
SET(CMAKE_CXX_STANDARD_REQUIRED ON)
SET(CMAKE_EXPORT_COMPILE_COMMANDS ON)
SET(CMAKE_CXX_FLAGS
  "${CMAKE_CXX_FLAGS}
   /EHsc
   /Zc:preprocessor
   -DNOMINMAX
   -D_USE_MATH_DEFINES"
)
ADD_DEFINITIONS(-D_CRT_SECURE_NO_WARNINGS -DCMAKE_GENERATOR_PLATFORM=x64)
MESSAGE(VCPKG_ROOT = " ${CMAKE_TOOLCHAIN_FILE} ")

# --------------------------------

IF(CMAKE_GENERATOR MATCHES "Visual Studio")
	ADD_COMPILE_OPTIONS(${COMMON_COMPILE_OPTIONS})
    SET(COMPILE_FLAGS ${COMMON_COMPILE_FLAGS})
    SET(CMAKE_CXX_SCAN_FOR_MODULES OFF)
    SET(CMAKE_INCREMENTAL_LINKING ON)
  	# Only set runtime library when top-level; let parent control this when embedded
  	# Note: you can make this configurable if needed.
  	# MultiThreadedDebugDLL is MSVC /MDd; ensure this matches your needs.
  	IF(EDXLIB_TOPLEVEL_EARLY)
  	  SET(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDebugDLL")
  	ENDIF()
  	ADD_COMPILE_DEFINITIONS(${COMMON_COMPILE_DEF})
  	MESSAGE("Added Compile Definitions: ${COMMON_COMPILE_DEF}")
ENDIF()

# --------------------------------
# REQUIRE BUILDS TO BE OUTSIDE OF SOURCE TREE.
# --------------------------------
FILE(TO_CMAKE_PATH "${PROJECT_BINARY_DIR}/CMakeLists.txt" LOC_PATH)

IF(EXISTS "${LOC_PATH}")
    MESSAGE(FATAL_ERROR "You cannot build in a source directory (or any directory with a CMakeLists.txt file). Please use a build directory instead.")
ENDIF()

# SET DEFAULT BUILD TYPES
IF(NOT CMAKE_BUILD_TYPE OR CMAKE_BUILD_TYPE STREQUAL "")
	SET(CMAKE_BUILD_TYPE "Debug" CACHE STRING "" FORCE)
ENDIF()

# --------------------------------
# edX Project Setup
# --------------------------------
PROJECT(edX
    VERSION 1.0.0
    DESCRIPTION "Custom file format for Scenery Editor X"
    LANGUAGES CXX C
    HOMEPAGE_URL "https://github.com/Coalition-of-Freeware-Developers/edX-Library"
)

# --------------------------------

# Compute top-level status (fallback for older CMake)
IF(NOT DEFINED PROJECT_IS_TOP_LEVEL)
	SET(PROJECT_IS_TOP_LEVEL ${EDXLIB_TOPLEVEL_EARLY})
ENDIF()

# Only set platform-specific globals and VS startup when top-level
IF(PROJECT_IS_TOP_LEVEL)
	SET_PROPERTY(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT edX)
	# --------------------------------
  	IF(NOT CMAKE_BUILD_TYPE OR CMAKE_BUILD_TYPE STREQUAL "")
    	SET(CMAKE_BUILD_TYPE "Debug" CACHE STRING "" FORCE)
  	ENDIF()
ENDIF()

# --------------------------------
# Testing and options
# --------------------------------
INCLUDE(CTest)

OPTION(EDXLIB_VENDOR_DEPS "Allow edX to vendor/add_subdirectory 3rd-party deps" ${PROJECT_IS_TOP_LEVEL})
OPTION(EDXLIB_BUILD_TESTS "Build edX tests" ${PROJECT_IS_TOP_LEVEL})
OPTION(EDXLIB_INSTALL "Generate install/export targets" ${PROJECT_IS_TOP_LEVEL})

# If parent enabled CTest globally, ensure tests are on here too.
IF(BUILD_TESTING)
	SET(EDXLIB_BUILD_TESTS ON CACHE BOOL "Build edX tests" FORCE)
ENDIF()

MESSAGE(STATUS "=================================================")
MESSAGE(STATUS "Beginning project generation for edX")
MESSAGE(STATUS "=================================================")

# --------------------------------
# Dependencies
# --------------------------------
FIND_PACKAGE(nlohmann_json CONFIG REQUIRED)


############################################
# X-Plane Scenery Library (XPLIB via FetchContent)
############################################
IF(FETCHCONTENT_XPLIB AND CMAKE_VERSION VERSION_GREATER_EQUAL 3.11)
    FETCHCONTENT_DECLARE(
        XPSceneryLib
        GIT_REPOSITORY https://github.com/Coalition-of-Freeware-Developers/X-PlaneSceneryLibrary.git
        GIT_TAG main
        GIT_SHALLOW TRUE
        GIT_PROGRESS TRUE
        GIT_SUBMODULES ""
    )
    FETCHCONTENT_GETPROPERTIES(XPSceneryLib)
    IF(NOT xpscenerylib_POPULATED)
        FETCHCONTENT_POPULATE(XPSceneryLib)
        IF(EXISTS "${xpscenerylib_SOURCE_DIR}/cmake/math.cmake")
            FILE(READ "${xpscenerylib_SOURCE_DIR}/cmake/math.cmake" XPSCENERYLIB_MATH_CMAKE)
            STRING(REPLACE "CMAKE_SOURCE_DIR" "CMAKE_CURRENT_SOURCE_DIR" XPSCENERYLIB_MATH_CMAKE "${XPSCENERYLIB_MATH_CMAKE}")
            FILE(WRITE "${xpscenerylib_SOURCE_DIR}/cmake/math.cmake" "${XPSCENERYLIB_MATH_CMAKE}")
        ENDIF()
        ADD_SUBDIRECTORY("${xpscenerylib_SOURCE_DIR}" "${xpscenerylib_BINARY_DIR}")
    ENDIF()
ENDIF()


# --------------------------------
# Catch2 (for tests only)
# --------------------------------
IF(EDXLIB_BUILD_TESTS)
	FIND_PACKAGE(Catch2 3 CONFIG QUIET)
	IF(NOT Catch2_FOUND AND EDXLIB_VENDOR_DEPS)
		IF(NOT TARGET Catch2::Catch2)
		ADD_SUBDIRECTORY(${CMAKE_CURRENT_SOURCE_DIR}/dependency/Catch2 EXCLUDE_FROM_ALL)
    	ENDIF()
  	ENDIF()
ENDIF()

# --------------------------------
# TESTS
# --------------------------------
IF(EDXLIB_BUILD_TESTS)
	ENABLE_TESTING()
	ADD_SUBDIRECTORY(tests)
ENDIF()

# --------------------------------
# ADD edX LIBRARY
# --------------------------------
INCLUDE(cmake/edx.cmake)

# --------------------------------
# Platform compile definitions for edX
# --------------------------------
## Public include dirs for build/install usage
IF(TARGET edX)
	INCLUDE(GNUInstallDirs)
	TARGET_INCLUDE_DIRECTORIES(edX
	  PUBLIC
	    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/edX/includes;${CMAKE_CURRENT_SOURCE_DIR}>
	    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
	)
	# Ensure no absolute source paths leak into INTERFACE includes
	SET_PROPERTY(TARGET edX PROPERTY INTERFACE_INCLUDE_DIRECTORIES
	  "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/edX/includes;${CMAKE_CURRENT_SOURCE_DIR}>;$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>")
	# Provide a namespaced alias for consumers
	IF(NOT TARGET edX::edX)
		ADD_LIBRARY(edX::edX ALIAS edX)
	ENDIF()
ENDIF()

IF(WIN32)
	FOREACH(TARGET IN ITEMS edX)
		TARGET_COMPILE_DEFINITIONS(${TARGET} PUBLIC
		  $<$<CONFIG:Debug>:EDX_WIN_DEBUG>
		  $<$<CONFIG:Release>:EDX_WIN_RELEASE>
		  UNICODE _UNICODE _CRT_SECURE_NO_WARNINGS
		)
	ENDFOREACH()
ELSEIF(UNIX)
	FOREACH(TARGET IN ITEMS edX)
		TARGET_COMPILE_DEFINITIONS(${TARGET} PUBLIC
		  $<$<CONFIG:Debug>:EDX_UNIX_DEBUG>
		  $<$<CONFIG:Release>:EDX_UNIX_RELEASE>
		  UNICODE _UNICODE _CRT_SECURE_NO_WARNINGS
		)
	ENDFOREACH()
ELSEIF(APPLE)
	FOREACH(TARGET IN ITEMS edX)
		TARGET_COMPILE_DEFINITIONS(${TARGET} PUBLIC
		  $<$<CONFIG:Debug>:EDX_MAC_DEBUG>
		  $<$<CONFIG:Release>:EDX_MAC_RELEASE>
		  UNICODE _UNICODE _CRT_SECURE_NO_WARNINGS
		)
	ENDFOREACH()
ENDIF()

# Group vendor targets only if they exist
IF(TARGET Catch2)
	SET_PROPERTY(TARGET Catch2 PROPERTY FOLDER "Dependency/Catch2")
ENDIF()

IF(TARGET Catch2WithMain)
	SET_PROPERTY(TARGET Catch2WithMain PROPERTY FOLDER "Dependency/Catch2")
ENDIF()

# --------------------------------
# Output directories (only when top-level; don’t override parent)
# --------------------------------
IF(PROJECT_IS_TOP_LEVEL)
	FOREACH(TARGET IN ITEMS EdxTests Catch2 Catch2WithMain edX XPSceneryLib)
		IF(TARGET ${TARGET})
			SET_TARGET_PROPERTIES(${TARGET} PROPERTIES
			  ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin
			  LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin
			  RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin
			)
		ENDIF()
	ENDFOREACH()

	FOREACH(OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES})
		SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_CURRENT_SOURCE_DIR}/bin/${OUTPUTCONFIG})
		SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_CURRENT_SOURCE_DIR}/bin/${OUTPUTCONFIG})
		SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_CURRENT_SOURCE_DIR}/bin/${OUTPUTCONFIG})
	ENDFOREACH()
ENDIF()

# --------------------------------
## Install/export for package consumption
# --------------------------------
IF(EDX_INSTALL)
	INCLUDE(GNUInstallDirs)
	INCLUDE(CMakePackageConfigHelpers)

	SET(EDX_INSTALL_CONFIG_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/edX")

	# Install the library target and headers
	INSTALL(TARGETS edX
	  EXPORT edXTargets
	  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
	  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
	  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
	  INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
	)

	INSTALL(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/edX/includes/
	        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/edX)

	# Also install configuration headers used by consumers (e.g., edX/config/edX_config.h)
	INSTALL(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/edX/config/
	        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/edX/config
	        FILES_MATCHING PATTERN "*.h")

	INSTALL(EXPORT edXTargets
	        NAMESPACE edX::
	        DESTINATION ${EDX_INSTALL_CONFIG_DIR})

	# Generate Config and Version files
	SET(PACKAGE_INCLUDE_INSTALL_DIR "${CMAKE_INSTALL_INCLUDEDIR}")

	SET(EDX_CONFIG_IN "${CMAKE_CURRENT_BINARY_DIR}/_edx_config.cmake.in")
	FILE(WRITE "${EDX_CONFIG_IN}" "@PACKAGE_INIT@\n\ninclude(CMakeFindDependencyMacro)\n\n# Re-export public dependencies\nfind_dependency(Stb)\nif(@EDX_WITH_TRACY@)\n  find_dependency(tracy)\nendif()\n\n# Imported targets\ninclude(\"${CMAKE_CURRENT_LIST_DIR}/edXTargets.cmake\")\n\n# Convenience variables\nset(edX_INCLUDE_DIR \"@PACKAGE_INCLUDE_INSTALL_DIR@/edX\")\nset(edX_NAMESPACE \"edX::\")\n")

	CONFIGURE_PACKAGE_CONFIG_FILE(
	  "${EDX_CONFIG_IN}"
	  ${CMAKE_CURRENT_BINARY_DIR}/edXConfig.cmake
	  INSTALL_DESTINATION ${EDX_INSTALL_CONFIG_DIR}
	  PATH_VARS PACKAGE_INCLUDE_INSTALL_DIR
	)

	WRITE_BASIC_PACKAGE_VERSION_FILE(
	  ${CMAKE_CURRENT_BINARY_DIR}/edXConfigVersion.cmake
	  VERSION ${PROJECT_VERSION}
	  COMPATIBILITY SameMajorVersion
	)

  	INSTALL(FILES
  	    ${CMAKE_CURRENT_BINARY_DIR}/edXConfig.cmake
  	    ${CMAKE_CURRENT_BINARY_DIR}/edXConfigVersion.cmake
  	  DESTINATION ${EDX_INSTALL_CONFIG_DIR}
  	)
ENDIF()

# --------------------------------
## Uninstall target (uses install manifest)
# --------------------------------
IF(NOT TARGET uninstall)
	SET(_EDX_UNINSTALL_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/edx_uninstall.cmake")
	FILE(WRITE "${_EDX_UNINSTALL_SCRIPT}" "if(NOT EXISTS \"${CMAKE_CURRENT_BINARY_DIR}/install_manifest.txt\")\n  message(FATAL_ERROR \"Cannot find install manifest: ${CMAKE_CURRENT_BINARY_DIR}/install_manifest.txt\")\nendif()\nfile(READ \"${CMAKE_CURRENT_BINARY_DIR}/install_manifest.txt\" _files)\nstring(REGEX REPLACE \"\\r?\\n\" \";\" _files \"${_files}\")\nforeach(_file ${_files})\n  if(EXISTS \"${_file}\" OR IS_SYMLINK \"${_file}\")\n    message(STATUS \"Removing ${_file}\")\n    file(REMOVE_RECURSE \"${_file}\")\n  endif()\nendforeach()\n")
	ADD_CUSTOM_TARGET(uninstall
	  COMMAND ${CMAKE_COMMAND} -P "${_EDX_UNINSTALL_SCRIPT}"
	  COMMENT "Uninstalling edX..."
	)
ENDIF()

# --------------------------------

