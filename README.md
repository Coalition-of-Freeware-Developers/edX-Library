# Scenery Editor X - edX File Format Library

## Overview

The edX file format library provides a modern, JSON-based file format system for Scenery Editor X projects and asset libraries. This refactored version uses nlohmann::json for robust JSON handling and follows modern C++ practices with cross-platform compatibility.

## Features

- **JSON-Based Format**: Clean, human-readable format using industry-standard JSON
- **Cross-Platform**: Works on Windows, macOS, and Linux
- **Modern C++**: Uses C++20 features with smart pointers and proper RAII
- **Extensible**: Easy to add new properties and data structures
- **Validation**: Built-in validation for data integrity
- **Type Safety**: Strong typing with comprehensive error handling
- **Version Control Friendly**: Text-based format works well with Git

## File Format Structure

### Project Files (.edX)

Project files contain complete scenery project information:

```json
{
  "Project": {
    "name": "My Scenery Project",
    "editor-version": "2.0.0",
    "XPlaneVersion": "12.1.4-r3",
    "author": "Author Name",
    "editdate": "2025-07-11T10:30:00Z",
    "createdate": "2025-07-11T09:00:00Z",
    "description": "Description of the project"
  },
  "Airport": {
    "Name": "San Francisco International Airport",
    "ICAO": "KSFO",
    "IATA": "SFO",
    "FAA": "KSFO",
    "City": "San Francisco",
    "State": "California",
    "Country": "USA",
    "RegionCode": "US-W",
    "DatumLat": 37.618999,
    "DatumLon": -122.375,
    "Elevation": 13,
    "MagVar": -14.0,
    "TransitionAlt": 18000,
    "TransitionLevel": "FL180",
    "Tower": 120.5,
    "Ground": 121.8,
    "ATIS": 135.1
  },
  "Libraries": [
    {
      "Library": "Laminar Research Airport Scenery",
      "local-path": "./Resources/default scenery/airport scenery/library.txt",
      "entry-count": 5000,
      "uuid": "15da3863-07d1-462a-be65-3873058675f3",
      "short-id": "a1b2c3d4",
      "version": "12.1.4"
    }
  ],
  "Assets": [
    {
      "id": "Asset001",
      "unique-id": "a1b2c3d4",
      "latitude": 37.618999,
      "longitude": -122.375,
      "altitude": 642,
      "heading": 0.0,
      "associated-library": "6587fddb",
      "layer-id": "terminals",
      "group-id": "group1",
      "locked": false,
      "hidden": false,
      "selected": false,
      "other-properties": {
        "building-type": "Terminal"
      }
    }
  ],
  "Layers": [
    {
      "layer-id": "terminals",
      "name": "Terminal Buildings",
      "description": "Airport terminal structures",
      "locked": false,
      "hidden": false,
      "opacity": 1.0,
      "z-order": 1,
      "asset-ids": ["Asset001"]
    }
  ],
  "Settings": {
    "render-quality": "high",
    "auto-save": true
  }
}
```

### Library Files (.edxlib)

Library files contain reusable asset definitions:

```json
{
  "Library": {
    "name": "Demo Airport Objects",
    "path": "./libraries/demo",
    "version": "1.0.0",
    "author": "Author Name",
    "git-repository": "https://github.com/demo/airport-objects",
    "size-mb": 125.5,
    "description": "Demonstration library for airport objects",
    "last-modified": "2025-07-11T10:30:00Z"
  },
  "Objects": [
    {
      "id": "terminal_modern_01",
      "unique-id": "e4f5a2b1",
      "asset-type": "building",
      "name": "Modern Terminal Building",
      "description": "Large modern terminal with glass facade",
      "category": "terminal",
      "tags": ["modern", "glass", "large"],
      "object-path": "objects/terminals/modern_01.obj",
      "texture-path": "textures/terminals/modern_01_diff.png",
      "preview-image": "previews/modern_01.jpg",
      "properties": {
        "floors": 3,
        "capacity": 5000,
        "year_built": 2020,
        "has_jetways": true
      }
    }
  ]
}
```

## API Usage

### Basic Operations

```cpp
#include "edXManager.h"

// Create manager
edx::EdxManager manager;

// Create a new project
auto project = manager.create_project("My Project", "Author Name", "KSFO");

// Configure project
project->airport.name = "San Francisco International";
project->airport.datumLat = 37.618999;
project->airport.datumLon = -122.375;

// Add an asset
edx::SceneAsset asset;
asset.id = "Asset001";
asset.uniqueId = edx::generate_unique_id();
asset.latitude = 37.619;
asset.longitude = -122.376;
asset.heading = 45.0;
project->assets.push_back(asset);

// Save project
manager.save_project(*project, "MyProject.edX");

// Load project
auto loadedProject = manager.load_project("MyProject.edX");
```

### Library Operations

```cpp
// Create a new library
auto library = manager.create_library("My Library", "Author", "1.0.0");

// Add an object
edx::LibraryObject obj;
obj.id = "building_01";
obj.uniqueId = edx::generate_unique_id();
obj.name = "Office Building";
obj.assetType = "building";
obj.category = "commercial";
obj.objectPath = "objects/building_01.obj";
library->add_object(obj);

// Save library
manager.save_library(*library, "MyLibrary.edxlib");
```

### Quick Functions

```cpp
// Quick save/load without manager
auto project = edx::load_project_quick("project.edX");
if (project) {
    // Modify project...
    edx::save_project_quick(*project, "project.edX");
}
```

## Building

### Requirements

- C++20 compatible compiler (GCC 11+/Clang 12+/MSVC 19.3+)
- CMake 3.15 or higher
- nlohmann::json (via vcpkg manifest)

### CMake Integration

Installed package usage:

```cmake
find_package(edX CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE edX::edX)
```

Subdirectory usage (vendored):

```cmake
add_subdirectory(edX)
target_link_libraries(your_target PRIVATE edX::edX)
```

### Compilation

```bash
mkdir build
cd build
cmake ..
cmake --build .
```

### Linux quick start

```bash
chmod +x ./SetupProject.sh
./SetupProject.sh
```

Manual Linux steps:

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
ctest --test-dir build --output-on-failure
```

Artifacts are placed under `bin/<Config>/<OS>/` (e.g., `bin/Debug/Linux/`) when building at the top level. The shared library on Linux is named `edX.so` (no `lib` prefix) and is versioned using the project version with standard symlinks (e.g., `edX.so -> edX.so.1 -> edX.so.1.2.3`).

### Build options and versioning

- Version source of truth: `edX/config/resource.h`. CMake parses this to set the project version and target `VERSION/SOVERSION`.
- `EDX_CI_MODE` (default OFF): when ON, disables build-time version bumping (used by CI).
- `EDX_OVERRIDE_VERSION` (string): override the project version at configure time (used by CI to keep all platforms in sync).
- `EDX_INCREMENT_VERSION_ON_CONFIG` (Windows-only, default OFF): optionally bump the build number once during configure. Do not combine with CI or link-time bumps.
- `EDXLIB_INSTALL` (default ON when top-level): enables install/export targets and CPack packaging (ZIP/TGZ).
- Output directories are normalized to `bin/<Config>/<OS>/` where `<OS>` is one of `Windows`, `Mac`, or `Linux`.

## Architecture

### Class Hierarchy

- `edx::EdxManager` - Main API interface
- `edx::EdxProject` - Complete project container
- `edx::LibraryFile` - Library container
- Core structures:
  - `ProjectInfo` - Project metadata
  - `AirportInfo` - Airport data
  - `LibraryReference` - Library references
  - `SceneAsset` - Individual assets
  - `SceneLayer` - Layer organization
  - `Library` - Library metadata
  - `LibraryObject` - Library objects

### JSON Serialization

All structures implement `to_json()` and `from_json()` methods for automatic serialization using nlohmann::json.

### Error Handling

- Exception-safe operations
- Comprehensive validation
- Progress callbacks for long operations
- Detailed error reporting

## Migration from Legacy Format

The library includes conversion utilities for migrating from older text-based formats:

```cpp
edx::EdxManager manager;
bool success = manager.convert_legacy_project("old_format.txt", "new_format.edX");
```

## Cross-Platform Compatibility

The library uses standard C++ and cross-platform file I/O:

- Windows: Visual Studio 2022 (MSVC 19.3+) with C++20
- macOS: Clang 12+ with C++20
- Linux: GCC 11+ or Clang 12+ with C++20

## Performance Considerations

- JSON parsing is optimized for typical project sizes
- Memory usage scales with asset count
- File I/O uses streaming for large files
- Validation is optional for performance-critical scenarios

## Future Enhancements

- Binary format option for large projects
- Compression support
- Incremental loading/saving
- Multi-threading support for large operations
- Plugin system for custom asset types

## License

Copyright (c) 2025 Coalition of Freeware Developers
Licensed under the same terms as Scenery Editor X.

---
<div align="center">
  <ul>
    <a style="text-align: center, font-style: bold">Copyright © 2025 Coalition of Freeware Developers</a>
    <a style="text-align: center, font-style: bold, padding: 12">&ensp;&#10072;&ensp;</a>
    <a style="text-align: center, font-style: bold">All Rights Reserved</a>
    <a style="text-align: center, font-style: bold, padding: 12">&ensp;&#10072;&ensp;</a>
    <a style="text-align: center, font-style: bold">MIT License</a>
  </ul>
</div>
<div align="center">
<img src=https://github.com/user-attachments/assets/1d752157-ed53-4f5e-80f9-21c2fdcb2537 width=40%>
</div>

## Release process

- Releases are orchestrated from the `release` branch.
- To bump and publish a release automatically:
  - Tag-based: push a lightweight tag named `patch`, `minor`, or `major` pointing at a commit contained in `release`.
  - Manual: run the "Release build and publish" workflow and choose `bump` = `patch` | `minor` | `major`.
- The workflow chooses the current version (max of `resource.h`, latest `v*` tag, optional `EDX_CI_VERSION`), applies the bump (resets build to 0), updates `edX/config/resource.h`, commits/tag `vX.Y.Z`, then builds/tests/packages across Windows, macOS, and Linux.
