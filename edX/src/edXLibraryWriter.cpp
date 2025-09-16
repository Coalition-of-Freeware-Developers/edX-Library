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
* edXLibraryWriter.cpp
* -------------------------------------------------------
* Created: 27/5/2025
* -------------------------------------------------------
*/
#include <fstream>
#include <iostream>
#include <set>
#include <string>
#include <vector>
#include <edX/include/edXLibraryFile.h>
#include <XPLibraryPath.h>

/// ----------------------------------------------------------------------------

namespace edx
{

	std::string generateUniqueId()
	{
	    static std::set<std::string> uniqueIds; // Set to store generated uniqueIds

	    std::string uniqueId;
	    do
	        uniqueId = edx::generateRandomHexValue(); // Generate a random hexadecimal value
	    while (uniqueIds.contains(uniqueId));         // Check if the generated uniqueId already exists

	    uniqueIds.insert(uniqueId); // Add the generated uniqueId to the set

	    return uniqueId;
	}

	void writeEdxLibFile(const std::string &filename,
	                     const std::string &libraryName,
	                     const std::string &libraryVersion,
	                     const std::string &libraryAuthor,
	                     const std::string &libraryGit,
	                     const std::vector<edx::LibraryObject> &objects)
	{
	    std::ofstream file(filename);

	    if (!file.is_open())
	    {
	        std::cerr << "Error opening file for writing." << '\n';
	        return;
	    }

	    file << "[Library]\n";
	    file << "Name=" << libraryName << "\n";
	    file << "Version=" << libraryVersion << "\n";
	    file << "Author=" << libraryAuthor << "\n";
	    file << "Git=" << libraryGit << "\n";
	    file << "Objects=" << objects.size() << "\n\n";

	    for (const auto &object : objects)
	    {
	        file << "[Object]" << "Id=" << object.id
	             << "UniqueId=" << (object.uniqueId.empty() ? generateUniqueId() : object.uniqueId)
	             << "AssetType=" << object.assetType << "Properties=" << object.properties << "\n";
	    }
	}

}

/// ----------------------------------------------------------------------------
