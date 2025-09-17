#!/usr/bin/env bash
set -euo pipefail

echo "[edX-Library] Container CI build starting..."

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build-ci"

mkdir -p "${BUILD_DIR}"
pushd "${BUILD_DIR}" >/dev/null

BUILD_TYPE=${BUILD_TYPE:-Release}
USE_XPLIB=${EDX_USE_FETCHCONTENT_XPLIB:-OFF}

echo "Configuring with CMake (Ninja generator)"
cmake -G Ninja "${ROOT_DIR}" \
  -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
  -DEDXLIB_BUILD_TESTS=ON \
  -DEDX_CI_MODE=ON \
  -DEDX_USE_FETCHCONTENT_XPLIB="${USE_XPLIB}"

echo "Building..."
cmake --build . --config Release -- -k 0

echo "Running tests via CTest..."
ctest --output-on-failure -C "${BUILD_TYPE}"

echo "[edX-Library] CI build completed successfully."
