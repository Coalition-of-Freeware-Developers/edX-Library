/**
* -------------------------------------------------------
* Copyright (c) 2025 Thomas Ray
* Copyright (c) 2025 Coalition of Freeware Developers
* -------------------------------------------------------
* Mozilla Public License Version 2.0
* -------------------------------------------------------
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <https://www.gnu.org/licenses/>.
* -------------------------------------------------------
* edXConfig.h
* -------------------------------------------------------
* Created: 27/5/2025
* -------------------------------------------------------
*/
#pragma once
#include <chrono>
#include <filesystem>
#include <functional>
#include <memory>
#include <optional>
#include <stdexcept>
#include <string>
#include <nlohmann/json.hpp>

/// ----------------------------------------------------------------------------
// Detect platform
#if defined _WIN32 || defined __CYGWIN__
  #define EDX_PLATFORM_WINDOWS
#elif defined(__APPLE__)
  #define EDX_PLATFORM_MACOS
#elif defined(__linux__)
  #define EDX_PLATFORM_LINUX
#endif

/// ----------------------------------------------------------------------------

// Cross-platform DLL export/import macros
#if defined(EDX_PLATFORM_WINDOWS)
    #ifdef EDX_EXPORTS
        #define EDX_API __declspec(dllexport)
    #else
        #define EDX_API __declspec(dllimport)
  #endif
  #define EDX_LOCAL
#else
  #if __GNUC__ >= 4
    #define EDX_API __attribute__((visibility("default")))
    #define EDX_LOCAL __attribute__((visibility("hidden")))
  #else
    #define EDX_API
    #define EDX_LOCAL
  #endif
#endif

/// ----------------------------------------------------------------------------

// JSON namespace alias for convenience
using json = nlohmann::json;

// Include the resource file for versioning
#include "resource.h"

// Version information
namespace edx
{
    constexpr const char* VERSION = EDX_VERSION_STRING;
    constexpr int VERSION_MAJOR = EDX_MAJOR;
    constexpr int VERSION_MINOR = EDX_MINOR;
    constexpr int VERSION_PATCH = EDX_PATCH;
    constexpr int VERSION_BUILD = EDX_BUILD;
}

/// ----------------------------------------------------------------------------

