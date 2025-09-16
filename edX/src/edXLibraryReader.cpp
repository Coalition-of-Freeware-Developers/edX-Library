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
* edXLibraryReader.cpp
* -------------------------------------------------------
* Created: 27/5/2025
* -------------------------------------------------------
*/
#include <fstream>
#include <iostream>
#include <limits>
#include <edX/include/edXLibraryFile.h>

/// ----------------------------------------------------------------------------

namespace ProjectLibrarys
{
    class LibraryParser
    {
    public:
        static std::vector<edx::Library> parseLibraries(const std::string &filePath)
        {
            std::vector<edx::Library> libraries;
            std::ifstream file(filePath);
            if (!file.is_open())
            {
                std::cerr << "Failed to open file: " << filePath << '\n';
                return libraries;
            }

            std::string line;
            while (std::getline(file, line))
            {
                if (line == "[Library]")
                {
                    edx::Library library;
                    std::getline(file, library.name);
                    std::getline(file, library.path);
                    std::getline(file, library.version);
                    std::getline(file, library.author);
                    std::getline(file, library.gitRepository);
                    file >> library.sizeInMB;
                    file.ignore(std::numeric_limits<std::streamsize>::max(), '\n'); // Ignore the rest of the line

                    libraries.push_back(library);
                }
            }

            return libraries;
        }

        static std::vector<edx::LibraryObject> parseLibraryObjects(const std::string &filePath)
        {
            std::vector<edx::LibraryObject> libraryObjects;
            std::ifstream file(filePath);
            if (!file.is_open())
            {
                std::cerr << "Failed to open file: " << filePath << '\n';
                return libraryObjects;
            }

            std::string line;
            while (std::getline(file, line))
            {
                if (line == "[LibraryObject]")
                {
                    edx::LibraryObject libraryObject;
                    std::getline(file, libraryObject.id);
                    std::getline(file, libraryObject.uniqueId);
                    std::getline(file, libraryObject.assetType);

                    // Parse properties as JSON string
                    std::string propertiesStr;
                    std::getline(file, propertiesStr);
                    if (!propertiesStr.empty())
                    {
                        try
                        {
                            libraryObject.properties = json::parse(propertiesStr);
                        }
                        catch (const std::exception& e)
                        {
                            std::cerr << "Error parsing properties JSON: " << e.what() << '\n';
                            libraryObject.properties = json::object();
                        }
                    }

                    libraryObjects.push_back(libraryObject);
                }
            }

            return libraryObjects;
        }
    };

} // namespace ProjectLibrarys

/// ----------------------------------------------------------------------------
