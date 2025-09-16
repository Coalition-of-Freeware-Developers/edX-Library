# edX chainload toolchain: safe, compiler-conditional defaults

IF(DEFINED EDX_TOOLCHAIN_INCLUDED)
  RETURN()
ENDIF()
SET(EDX_TOOLCHAIN_INCLUDED ON)

# Helpful context
MESSAGE(STATUS "[edX] Applying chainloaded toolchain defaults (compiler-conditional flags)")

# Keep compile_commands.json for IDEs
SET(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "" FORCE)

# Require modern C++ for all targets by default unless overridden
SET(CMAKE_CXX_STANDARD 20 CACHE STRING "")
SET(CMAKE_CXX_STANDARD_REQUIRED ON)

# Apply compiler/platform-specific options safely
IF(MSVC)
  # MSVC-only language options
  ADD_COMPILE_OPTIONS(/EHsc /Zc:preprocessor)
  # Common Windows macros
  ADD_COMPILE_DEFINITIONS(NOMINMAX _USE_MATH_DEFINES _CRT_SECURE_NO_WARNINGS)
ELSEIF(WIN32)
  # Non-MSVC toolchains on Windows
  ADD_COMPILE_DEFINITIONS(NOMINMAX _USE_MATH_DEFINES)
ENDIF()

# Do not create targets here (toolchain runs before project()).
