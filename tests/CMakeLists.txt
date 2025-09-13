# -------------------------------------------------------
# Scenery Editor X - edX Format Library Tests
# -------------------------------------------------------
# Copyright (c) 2025 Thomas Ray
# Copyright (c) 2025 Coalition of Freeware Developers
# -------------------------------------------------------
# CMakeLists.txt for edX Format Library Tests
# -------------------------------------------------------
CMAKE_MINIMUM_REQUIRED(VERSION 3.16)

MESSAGE(STATUS "=================================================")
MESSAGE(STATUS "Generating edX Format Tests")

FILE(GLOB TEST_SOURCE_FILES
	${CMAKE_CURRENT_SOURCE_DIR}/edx_tests/EdxLibraryFileTest.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/edx_tests/EdxManagerTest.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/edx_tests/EdxProjectFileComprehensiveTest.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/edx_tests/EdxProjectFileTest.cpp
	${CMAKE_CURRENT_SOURCE_DIR}/edx_tests/EdxTestMain.cpp
)

ADD_EXECUTABLE(EdxTests
	${TEST_SOURCE_FILES}
)

# Include directories
TARGET_INCLUDE_DIRECTORIES(EdxTests PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/includes
    ${CMAKE_CURRENT_SOURCE_DIR}/dependency
)

# Link with Catch2 and other dependencies
TARGET_LINK_LIBRARIES(EdxTests PRIVATE
    Catch2::Catch2WithMain
    edX
    nlohmann_json::nlohmann_json
)

# Enable warning level
IF(MSVC)
    TARGET_COMPILE_OPTIONS(EdxTests PRIVATE /MP /W4 /utf-8)
ELSE()
    TARGET_COMPILE_OPTIONS(EdxTests PRIVATE -Wall -Wextra -Wpedantic)
ENDIF()

INCLUDE(Catch)
# Register with CTest
catch_discover_tests(EdxTests)

# --------------------------------
# edX Demo Generator (separate executable)
# --------------------------------

ADD_EXECUTABLE(EdxDemoGenerator
    ${CMAKE_CURRENT_SOURCE_DIR}/edx_tests/EdxDemoGenerator.cpp
)

# Include directories
TARGET_INCLUDE_DIRECTORIES(EdxDemoGenerator PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/includes
    ${CMAKE_CURRENT_SOURCE_DIR}/dependency
)

# Link with edX library
TARGET_LINK_LIBRARIES(EdxDemoGenerator PRIVATE
    edX
)

# Enable warning level
IF(MSVC)
    TARGET_COMPILE_OPTIONS(EdxDemoGenerator PRIVATE /MP /W4 /utf-8)
ELSE()
    TARGET_COMPILE_OPTIONS(EdxDemoGenerator PRIVATE -Wall -Wextra -Wpedantic)
ENDIF()
