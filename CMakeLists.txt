CMAKE_MINIMUM_REQUIRED(VERSION 3.8...4.0)

# --------------------------------
# Global Setup
# --------------------------------
## Using FetchContent_MakeAvailable; no CMP0169 override required

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

# Friendly OS name for output paths and packages (Darwin -> Mac)
SET(EDX_OUTPUT_OS_NAME ${CMAKE_SYSTEM_NAME})
IF(APPLE OR CMAKE_SYSTEM_NAME STREQUAL "Darwin")
	SET(EDX_OUTPUT_OS_NAME "Mac")
ENDIF()

SET(BIN_DIR ${CMAKE_SOURCE_DIR}/bin/${CMAKE_CFG_INTDIR}/${EDX_OUTPUT_OS_NAME})

# FetchContent is used optionally for pulling XPSceneryLib
IF(CMAKE_VERSION VERSION_GREATER_EQUAL 3.11)
	INCLUDE(FetchContent)
ENDIF()

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
# Version management and sync with resource.h
# --------------------------------
# resource.h is the single source of truth for the edX version (see scripts/increment_edx_build.py).
# Optionally increment the build number during CMake configure, then parse it and feed into project(VERSION ...)

# Option: increment build number during configure (keeps CMake version in sync on same build)
OPTION(EDX_INCREMENT_VERSION_ON_CONFIG "Increment edX build number during CMake configure (instead of PRE_BUILD)" OFF)

# Discover increment script path robustly (handle edX/edx casing)
SET(_EDX_VER_SCRIPT_1 "${CMAKE_CURRENT_SOURCE_DIR}/scripts/increment_edX_build.py")
SET(_EDX_VER_SCRIPT_2 "${CMAKE_CURRENT_SOURCE_DIR}/scripts/increment_edx_build.py")
IF(EXISTS "${_EDX_VER_SCRIPT_1}")
	SET(EDX_VERSION_SCRIPT "${_EDX_VER_SCRIPT_1}")
ELSEIF(EXISTS "${_EDX_VER_SCRIPT_2}")
	SET(EDX_VERSION_SCRIPT "${_EDX_VER_SCRIPT_2}")
ENDIF()

IF(EDX_INCREMENT_VERSION_ON_CONFIG AND WIN32)
	IF(EDX_VERSION_SCRIPT)
		FIND_PACKAGE(Python3 COMPONENTS Interpreter QUIET)
		IF(Python3_Interpreter_FOUND)
			EXECUTE_PROCESS(
				COMMAND ${Python3_EXECUTABLE} ${EDX_VERSION_SCRIPT}
				WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
				RESULT_VARIABLE _EDX_INC_RES
			)
			IF(_EDX_INC_RES EQUAL 0)
				MESSAGE(STATUS "Incremented edX build number during configure using ${EDX_VERSION_SCRIPT}")
			ELSE()
				MESSAGE(WARNING "Failed to increment edX version during configure (code ${_EDX_INC_RES}). Build-time step may still run.")
			ENDIF()
		ELSE()
			MESSAGE(WARNING "Python3 not found; cannot increment edX build number during configure. Falling back to build-time increment if enabled.")
		ENDIF()
	ELSE()
		MESSAGE(WARNING "increment_edx_build.py not found; skipping configure-time increment.")
	ENDIF()
ENDIF()

# If an override version is provided (e.g., by CI), use it; otherwise parse resource.h
SET(EDX_OVERRIDE_VERSION "" CACHE STRING "Override edX project version (CI use)")

IF(EDX_OVERRIDE_VERSION)
	SET(EDX_PROJECT_VERSION "${EDX_OVERRIDE_VERSION}")
	MESSAGE(STATUS "Using overridden edX version: ${EDX_PROJECT_VERSION}")
ELSE()
	# Derive project version from edX/config/resource.h
	# Parse EDX_MAJOR/MINOR/PATCH/BUILD and feed them into project(VERSION ...)
ENDIF()
SET(EDX_RESOURCE_H "${CMAKE_CURRENT_SOURCE_DIR}/edX/config/resource.h")
IF(EXISTS "${EDX_RESOURCE_H}")
	FILE(READ "${EDX_RESOURCE_H}" _edx_res_content)

	# Helper to extract integer defines from resource.h
	FUNCTION(_edx_extract_define NAME OUTVAR)
		STRING(REGEX MATCH "#[ \t]*define[ \t]+${NAME}[ \t]+([0-9]+)" _match "${_edx_res_content}")
		IF(_match)
			SET(${OUTVAR} "${CMAKE_MATCH_1}" PARENT_SCOPE)
		ENDIF()
	ENDFUNCTION()

	_edx_extract_define(EDX_MAJOR EDX_MAJOR_RAW)
	_edx_extract_define(EDX_MINOR EDX_MINOR_RAW)
	_edx_extract_define(EDX_PATCH EDX_PATCH_RAW)
	_edx_extract_define(EDX_BUILD EDX_BUILD_RAW)

	# Normalize any leading zeros and coerce to integers
	IF(DEFINED EDX_MAJOR_RAW)
		MATH(EXPR EDX_VERSION_MAJOR "${EDX_MAJOR_RAW}")
	ENDIF()
	IF(DEFINED EDX_MINOR_RAW)
		MATH(EXPR EDX_VERSION_MINOR "${EDX_MINOR_RAW}")
	ENDIF()
	IF(DEFINED EDX_PATCH_RAW)
		MATH(EXPR EDX_VERSION_PATCH "${EDX_PATCH_RAW}")
	ENDIF()
	IF(DEFINED EDX_BUILD_RAW)
		MATH(EXPR EDX_VERSION_TWEAK "${EDX_BUILD_RAW}")
	ENDIF()

	IF(DEFINED EDX_VERSION_MAJOR AND DEFINED EDX_VERSION_MINOR AND DEFINED EDX_VERSION_PATCH)
		IF(DEFINED EDX_VERSION_TWEAK)
			SET(EDX_PROJECT_VERSION "${EDX_VERSION_MAJOR}.${EDX_VERSION_MINOR}.${EDX_VERSION_PATCH}.${EDX_VERSION_TWEAK}")
		ELSE()
			SET(EDX_PROJECT_VERSION "${EDX_VERSION_MAJOR}.${EDX_VERSION_MINOR}.${EDX_VERSION_PATCH}")
		ENDIF()
	ENDIF()
ENDIF()

# Fallback if parsing failed
IF(NOT DEFINED EDX_PROJECT_VERSION)
	SET(EDX_VERSION_MAJOR 1)
	SET(EDX_VERSION_MINOR 0)
	SET(EDX_VERSION_PATCH 0)
	SET(EDX_PROJECT_VERSION "${EDX_VERSION_MAJOR}.${EDX_VERSION_MINOR}.${EDX_VERSION_PATCH}")
	MESSAGE(WARNING "Failed to determine version (no override and parse failed); defaulting to ${EDX_PROJECT_VERSION}")
ELSE()
	IF(NOT EDX_OVERRIDE_VERSION)
		MESSAGE(STATUS "edX version detected from resource.h: ${EDX_PROJECT_VERSION}")
	ENDIF()
ENDIF()

# --------------------------------
# edX Project Setup
# --------------------------------
PROJECT(edX
	VERSION ${EDX_PROJECT_VERSION}
    DESCRIPTION "Custom file format for Scenery Editor X"
    LANGUAGES CXX C
    HOMEPAGE_URL "https://github.com/Coalition-of-Freeware-Developers/edX-Library"
)

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
# Optionally fetch XPSceneryLib; default OFF so consumers can provide it externally
OPTION(EDX_USE_FETCHCONTENT_XPLIB "Fetch XPSceneryLib via CMake FetchContent" ON)
OPTION(EDX_CI_MODE "CI mode: disable build-time version increments" OFF)

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
IF(EDX_USE_FETCHCONTENT_XPLIB AND CMAKE_VERSION VERSION_GREATER_EQUAL 3.11)
	FETCHCONTENT_DECLARE(
		XPSceneryLib
		GIT_REPOSITORY https://github.com/Coalition-of-Freeware-Developers/X-PlaneSceneryLibrary.git
		GIT_TAG main
		GIT_SHALLOW TRUE
		GIT_PROGRESS TRUE
		GIT_SUBMODULES ""
	)
	# Prefer the modern helper which fetches and adds the subdirectory
	FETCHCONTENT_MAKEAVAILABLE(XPSceneryLib)

	# Create compatibility aliases if upstream uses a different target name
	IF(TARGET X-PlaneSceneryLibrary AND NOT TARGET XPSceneryLib)
		ADD_LIBRARY(XPSceneryLib ALIAS X-PlaneSceneryLibrary)
	ENDIF()
	IF(TARGET XPSceneryLib AND NOT TARGET XPSceneryLib::XPSceneryLib)
		ADD_LIBRARY(XPSceneryLib::XPSceneryLib ALIAS XPSceneryLib)
	ENDIF()

	# Ensure consistent UTF-8 on MSVC for the fetched target
	IF(MSVC)
		IF(TARGET XPSceneryLib)
			TARGET_COMPILE_OPTIONS(XPSceneryLib PRIVATE /utf-8)
		ELSEIF(TARGET X-PlaneSceneryLibrary)
			TARGET_COMPILE_OPTIONS(X-PlaneSceneryLibrary PRIVATE /utf-8)
		ENDIF()
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
	    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/edX/include;${CMAKE_CURRENT_SOURCE_DIR}>
	    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
	)
	# Ensure no absolute source paths leak into INTERFACE includes
	SET_PROPERTY(TARGET edX PROPERTY INTERFACE_INCLUDE_DIRECTORIES
	  "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/edX/include;${CMAKE_CURRENT_SOURCE_DIR}>;$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>")
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
	# Use structure: bin/${OUTPUTCONFIG}/${CMAKE_SYSTEM_NAME}
	FOREACH(OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES})
    	SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_CURRENT_SOURCE_DIR}/bin/${OUTPUTCONFIG}/${EDX_OUTPUT_OS_NAME})
    	SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_CURRENT_SOURCE_DIR}/bin/${OUTPUTCONFIG}/${EDX_OUTPUT_OS_NAME})
    	SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_CURRENT_SOURCE_DIR}/bin/${OUTPUTCONFIG}/${EDX_OUTPUT_OS_NAME})
	ENDFOREACH()

	# Also set per-target generic outputs to a config-resolved path for multi-config generators
	FOREACH(TARGET IN ITEMS EdxTests Catch2 Catch2WithMain edX XPSceneryLib)
		IF(TARGET ${TARGET})
						SET_TARGET_PROPERTIES(${TARGET} PROPERTIES
							ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin/${CMAKE_CFG_INTDIR}/${EDX_OUTPUT_OS_NAME}
							LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin/${CMAKE_CFG_INTDIR}/${EDX_OUTPUT_OS_NAME}
							RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin/${CMAKE_CFG_INTDIR}/${EDX_OUTPUT_OS_NAME}
						)
		ENDIF()
	ENDFOREACH()
ENDIF()

# --------------------------------
## Install/export for package consumption
# --------------------------------
IF(EDXLIB_INSTALL)
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

	INSTALL(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/edX/include/
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
## Packaging (CPack)
# --------------------------------
SET(CPACK_PACKAGE_NAME "edX")
SET(CPACK_PACKAGE_VENDOR "Coalition of Freeware Developers")
SET(CPACK_PACKAGE_CONTACT "https://github.com/Coalition-of-Freeware-Developers/edX-Library")
SET(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
SET(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${EDX_OUTPUT_OS_NAME}-${CMAKE_SYSTEM_PROCESSOR}-${CPACK_PACKAGE_VERSION}")
SET(CPACK_GENERATOR "TGZ;ZIP")
INCLUDE(CPack)

# --------------------------------

