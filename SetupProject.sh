#!/usr/bin/env bash
set -euo pipefail

# Quick Linux setup script for edX-Library
# - Configures out-of-source build under ./build
# - Uses the local vcpkg manifest and toolchain
# - Builds library and tests

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
BUILD_DIR="${ROOT_DIR}/build"

echo "==> edX-Library: Linux setup"
echo "Root: ${ROOT_DIR}"

# Optional: bootstrap vcpkg if present as submodule
if [[ -d "${ROOT_DIR}/dependency/vcpkg" ]]; then
  echo "==> Bootstrapping vcpkg (if needed)"
  pushd "${ROOT_DIR}/dependency/vcpkg" >/dev/null
  if [[ ! -f ./vcpkg ]]; then
    ./bootstrap-vcpkg.sh -disableMetrics
  fi
  popd >/dev/null
fi

mkdir -p "${BUILD_DIR}"
pushd "${BUILD_DIR}" >/dev/null

echo "==> Configuring CMake"
cmake .. \
  -DCMAKE_BUILD_TYPE=Debug

echo "==> Building edX (all targets)"
cmake --build . --config Debug -j

echo "==> Running tests (if built)"
ctest -C Debug --output-on-failure || true

echo "==> Artifacts under: ${ROOT_DIR}/bin/$(uname)/Debug"
popd >/dev/null

echo "Done."
