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
* edXTimeUtils.cpp
* -------------------------------------------------------
* Created: 27/5/2025
* -------------------------------------------------------
*/
#include <iomanip>
#include <sstream>
#include <edX/include/edXTimeUtils.h>

/// ----------------------------------------------------------------------------

namespace edx
{
    std::string time_point_to_iso_string(const std::chrono::system_clock::time_point& tp)
    {
        const auto time_t = std::chrono::system_clock::to_time_t(tp);
        std::stringstream ss;
        ss << std::put_time(std::gmtime(&time_t), "%Y-%m-%dT%H:%M:%SZ");
        return ss.str();
    }

    std::chrono::system_clock::time_point iso_string_to_time_point(const std::string& iso_string)
    {
        std::tm tm = {};
        std::stringstream ss(iso_string);
        ss >> std::get_time(&tm, "%Y-%m-%dT%H:%M:%SZ");
        return std::chrono::system_clock::from_time_t(std::mktime(&tm));
    }

} // namespace edx

/// ----------------------------------------------------------------------------
