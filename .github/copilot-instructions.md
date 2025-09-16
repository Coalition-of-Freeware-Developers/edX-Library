## edX-Library – Copilot instructions for AI coding agents

This repo builds a C++20 shared library for the Scenery Editor X file format (“edX”), plus tests. Use these project-specific notes to be productive fast.

### Architecture and key code
- Library target: `edX` (shared). Public alias: `edX::edX`.
- Public API header: `edX/include/edXManager.h` (main entry point). Patterns:
  - High-level operations: `EdxManager::create_project/load_project/save_project`, `create_library/load_library/save_library`.
  - Convenience functions: `edx::load_project_quick/save_project_quick`, `load_library_quick/save_library_quick`, `generate_unique_id()`.
  - Progress and error callbacks are std::function-based; avoid blocking calls inside callbacks.
- Data model (JSON-serializable): see `edX/include/edXProjectFile.h` and `edX/include/edXLibraryFile.h`.
  - Each struct implements `to_json(json&)` and `from_json(const json&)` using nlohmann::json.
  - Example types: `ProjectInfo`, `AirportInfo`, `LibraryReference`, `SceneAsset`, `SceneLayer`, and top-level `EdxProject`.
- I/O and helpers live in `edX/src/*` with readers/writers per format: `edXReader/Writer.cpp`, `edXLibraryReader/Writer.cpp`.

### Dependencies and integration
- JSON: `nlohmann_json::nlohmann_json` via vcpkg manifest (`vcpkg.json`).
- Optional: `XPSceneryLib` can be auto-fetched when `EDX_USE_FETCHCONTENT_XPLIB=ON` (default). Code must gracefully skip if the target is absent.
- Windows build number is incremented by `scripts/increment_edx_build.py` (PRE_BUILD); do not hand-edit `edX/config/resource.h`.

### Build and test workflows
- Out-of-source only; CMake errors if run in source tree.
- Quick Windows setup: run `SetupProject.bat` (shows progress, logs to `CMake_Gen.log`, creates `build/`).
- Manual CMake:
  - Configure: from a fresh `build/` dir, `cmake ..` (vcpkg toolchain auto-detected from `dependency/vcpkg/…` when top-level).
  - Build: `cmake --build build --config Debug` (multi-config) or `cmake --build build` (single-config).
- Artifacts: top-level builds put binaries under `bin/<Config>/` when top-level; internal `edx.cmake` also sets `CMAKE_BINARY_DIR/bin` for the library.
- Tests: `EDXLIB_BUILD_TESTS` defaults ON when top-level. Targets: `EdxTests` (Catch2 v3) and `EdxDemoGenerator`.
  - Run via CTest: `ctest -C Debug --output-on-failure` from `build/`.
  - Direct exe: `bin/Debug/EdxTests.exe` (Windows, from repo root after building). Ensure `edX.dll` is discoverable (same dir).

### Coding conventions and patterns
- Language/tooling: C++20, MSVC `/utf-8` on Windows, UNICODE defines. Export macro is `EDX_API` from `edX/config/edXConfig.h`; the DLL build defines `EDX_EXPORTS` internally—do not propagate it to consumers.
- Public headers live in `edX/include`; keep implementation in `edX/src`. Add new public API only via headers under `edX/include`.
- Serialization: implement `to_json/from_json` on new structs; keep JSON key schema stable and align with examples in `docs/edx File Format Documentation.md` and root `README.md`.
- Validation: prefer adding checks to `EdxManager::validate_project/validate_library` rather than ad-hoc validation.
- Optional fields use smart pointers (e.g., frequencies in `AirportInfo`); preserve nullability through JSON.

### JSON serialization keys and casing
- Top-level keys: `Project`, `Airport`, `Libraries`, `Assets`, `Layers`, optional `Settings`.
- `ProjectInfo` keys: `name`, `editor-version`, `XPlaneVersion`, `author`, `editdate`, `createdate`, `description`.
- `AirportInfo` keys (note casing): `Name`, `ICAO`, `IATA`, `FAA`, `City`, `State`, `Country`, `RegionCode`, `DatumLat`, `DatumLon`, `Elevation`, `MagVar`, `TransitionAlt`, `TransitionLevel`, optional frequencies `CTAF`, `ATIS`, `Tower`, `Ground`, `Approach`, `Departure`, `Clearance`.
- `LibraryReference` keys: `Library`, `local-path`, `entry-count`, `uuid`, `short-id`, `version`.
- `SceneAsset` keys: `id`, `unique-id`, `latitude`, `longitude`, `altitude`, `heading`, `associated-library`, `layer-id`, `group-id`, `locked`, `hidden`, `selected`, optional `other-properties` (free-form JSON).
- `SceneLayer` keys: `layer-id`, `name`, `description`, `locked`, `hidden`, `opacity`, `z-order`, `asset-ids`, optional `layer-properties` (JSON).
- Example: see `docs/edx File Format Documentation.md` for canonical field names; keep exact hyphenation and capitalization.

#### Key-to-member quick map (common)
| External JSON key | Internal member |
|---|---|
| Project.name | ProjectInfo::name |
| Project.editor-version | ProjectInfo::editorVersion |
| Project.XPlaneVersion | ProjectInfo::xplaneVersion |
| Project.author | ProjectInfo::author |
| Project.editdate | ProjectInfo::editDate |
| Project.createdate | ProjectInfo::createDate |
| Project.description | ProjectInfo::description |
| Airport.Name | AirportInfo::name |
| Airport.ICAO | AirportInfo::icao |
| Airport.IATA | AirportInfo::iata |
| Airport.FAA | AirportInfo::faa |
| Airport.City | AirportInfo::city |
| Airport.State | AirportInfo::state |
| Airport.Country | AirportInfo::country |
| Airport.RegionCode | AirportInfo::regionCode |
| Airport.DatumLat | AirportInfo::datumLat |
| Airport.DatumLon | AirportInfo::datumLon |
| Airport.Elevation | AirportInfo::elevation |
| Airport.MagVar | AirportInfo::magneticVariation |
| Airport.TransitionAlt | AirportInfo::transitionAltitude |
| Airport.TransitionLevel | AirportInfo::transitionLevel |
| Airport.CTAF (etc.) | AirportInfo::{ctaf, atis, tower, ground, approach, departure, clearance} |
| Libraries[].Library | LibraryReference::name |
| Assets[].altitude | SceneAsset::altitude |
| Assets[].heading | SceneAsset::heading |
| Assets[].associated-library | SceneAsset::associatedLibrary |
| Assets[].layer-id | SceneAsset::layerId |
| Layers[].layer-id | SceneLayer::layerId |
| Layers[].name | SceneLayer::name |
| Layers[].z-order | SceneLayer::zOrder |
| Layers[].asset-ids | SceneLayer::assetIds |
- Test targets: `EdxTests` (Catch2 v3) and `EdxDemoGenerator`.
- Common Catch2 tags seen in this repo: `[project]`, `[manager]`, `[serialization]`, `[validation]`, `[integration]`, `[file-generation]`, `[airport]`, `[assets]`, `[edge-cases]`, `[performance]`.
- Run by tag (Windows, after building):
  - From build dir via CTest: `ctest -C Debug -R EdxTests --output-on-failure`.
- Keep XPSceneryLib optional: guard links with `if(TARGET XPSceneryLib::XPSceneryLib)`; never hard-require it.
- Do not introduce global singletons; use `EdxManager` for cross-cutting operations and callbacks.
  - `auto m = edx::EdxManager{}; auto lib = m.create_library("My Library", "Author", "1.0.0"); m.save_library(*lib, "MyLibrary.edxlib"); auto loaded = m.load_library("MyLibrary.edxlib");`

- Windows build number auto-increment script lives at `scripts/increment_edx_build.py` and is invoked during Windows builds; do not edit `edX/config/resource.h` manually. If a build error mentions `increment_edX_build.py`, verify the path/casing in `cmake/edx.cmake` aligns with the actual filename.

- Top-level: `Library` (metadata), `Objects` (array of `LibraryObject`).
- `Library` keys: `name`, `path`, `version`, `author`, `git-repository`, `size-mb`, `description`, `last-modified` → members on `Library`.
  - `Objects[].id` → `LibraryObject::id`, `Objects[].unique-id` → `LibraryObject::uniqueId`, `Objects[].asset-type` → `LibraryObject::assetType`

| Library.name | Library::name |
| Library.path | Library::path |
| Library.author | Library::author |
| Library.git-repository | Library::gitRepository |
| Objects[].unique-id | LibraryObject::uniqueId |
| Objects[].asset-type | LibraryObject::assetType |
| Objects[].name | LibraryObject::name |
| Objects[].description | LibraryObject::description |
| Objects[].category | LibraryObject::category |
| Objects[].tags | LibraryObject::tags |
| Objects[].object-path | LibraryObject::objectPath |
| Objects[].texture-path | LibraryObject::texturePath |
| Objects[].preview-image | LibraryObject::previewImage |
| Objects[].properties | LibraryObject::properties |
- Minimal example:

```json
{
  "Library": {
    "name": "Demo Airport Objects",
    "version": "1.0.0",
    "author": "Author Name"
  },
  "Objects": [
    {
      "id": "terminal_modern_01",
      "unique-id": "e4f5a2b1",
      "asset-type": "building",
      "object-path": "objects/terminals/modern_01.obj",
    }
  ]
}
```

### Release automation (semantic bump)
- Source branch: `release`.
- Tag-triggered bump: push a lightweight tag named `patch`, `minor`, or `major` that points to a commit contained in `release`. The workflow will:
  - Pick the current version as the max of `resource.h`, latest `v*` tag, and optional `EDX_CI_VERSION`.
  - Bump the requested segment (resets build number to 0), update `edX/config/resource.h`, commit to `release`, and create tag `vX.Y.Z`.
  - Build, test, and package on Linux, macOS (per-arch), and Windows using `EDX_CI_MODE=ON` and `EDX_OVERRIDE_VERSION`.
- Manual dispatch: run the "Release build and publish" workflow with input `bump` = `patch` | `minor` | `major`. It bumps from the latest `release` head and performs the same steps.
- Build number: CI disables build-number auto-increment to keep published artifacts deterministic; local Windows builds still increment at link time as before.
