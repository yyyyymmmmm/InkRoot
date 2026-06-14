#!/usr/bin/env python3
import re
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: release_notes.py CHANGELOG.md VERSION", file=sys.stderr)
        return 2

    changelog = Path(sys.argv[1]).read_text(encoding="utf-8")
    version = re.escape(sys.argv[2])
    match = re.search(
        rf"^## \[{version}\][^\n]*\n(?P<body>.*?)(?=^## \[|\Z)",
        changelog,
        re.M | re.S,
    )
    if not match:
        print(f"Release notes for {sys.argv[2]} were not found.", file=sys.stderr)
        return 1

    body = match.group("body").strip()
    print(body if body else f"InkRoot {sys.argv[2]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
