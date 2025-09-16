#!/usr/bin/env python3
"""
Update edX/config/resource.h version macros to match a provided version.

Usage:
  python scripts/set_edx_version.py 1.2.3[.4]

Updates:
  - EDX_MAJOR, EDX_MINOR, EDX_PATCH, EDX_BUILD
  - EDX_VERSION_STRING
  - EDX_VERSION (hex packed: MAJ<<24 | MIN<<16 | PAT<<8 | BLD)
"""
from __future__ import annotations
import re
import sys
from pathlib import Path


def parse_version(s: str):
    parts = s.strip().split(".")
    if len(parts) < 3 or len(parts) > 4:
        raise SystemExit(f"Version must be X.Y.Z or X.Y.Z.W, got: {s}")
    major = int(parts[0])
    minor = int(parts[1])
    patch = int(parts[2])
    build = int(parts[3]) if len(parts) == 4 else 0
    return major, minor, patch, build


def pack_hex(major: int, minor: int, patch: int, build: int) -> str:
    val = (major << 24) | (minor << 16) | (patch << 8) | (build & 0xFF)
    return f"0x{val:08X}"


def main(argv: list[str]):
    if len(argv) < 2:
        raise SystemExit("Usage: python scripts/set_edx_version.py <X.Y.Z[.W]>")

    version = argv[1].lstrip("v")
    major, minor, patch, build = parse_version(version)
    version_str = f"{major}.{minor}.{patch}.{build}" if build else f"{major}.{minor}.{patch}"
    hex_ver = pack_hex(major, minor, patch, build)

    repo_root = Path(__file__).resolve().parents[1]
    res_path = repo_root / "edX" / "config" / "resource.h"
    if not res_path.exists():
        raise SystemExit(f"resource.h not found at {res_path}")

    content = res_path.read_text(encoding="utf-8")

    def sub_define(name: str, value: int) -> None:
        nonlocal content
        pattern = rf"^(#define\s+{re.escape(name)}\s+)(\d+).*$"
        repl = rf"\g<1>{value}"
        content, n = re.subn(pattern, repl, content, flags=re.MULTILINE)
        if n == 0:
            # Insert define if missing
            content = content + f"\n#define {name}\t\t\t{value}\n"

    sub_define("EDX_MAJOR", major)
    sub_define("EDX_MINOR", minor)
    sub_define("EDX_PATCH", patch)
    sub_define("EDX_BUILD", build)

    # Update EDX_VERSION_STRING
    content = re.sub(
        r'^(#define\s+EDX_VERSION_STRING\s+\")[^"]*(\")\s*$',
        rf"\g<1>{version_str}\g<2>",
        content,
        flags=re.MULTILINE,
    )

    # Update EDX_VERSION (hex)
    content = re.sub(
        r'^(#define\s+EDX_VERSION\s+)0x[0-9A-Fa-f]+\s*$',
        rf"\g<1>{hex_ver}",
        content,
        flags=re.MULTILINE,
    )

    res_path.write_text(content, encoding="utf-8")
    print(f"Updated resource.h version to {version_str} ({hex_ver})")


if __name__ == "__main__":
    main(sys.argv)
