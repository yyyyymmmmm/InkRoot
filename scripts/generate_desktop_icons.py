#!/usr/bin/env python3
"""Generate macOS and Windows desktop icons from the app logo.

The script intentionally relies only on macOS built-in tools plus Python's
standard library so release machines do not need Pillow or ImageMagick.
"""

from __future__ import annotations

import os
import shutil
import struct
import subprocess
import tempfile
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
LOGO_PATH = PROJECT_ROOT / "assets/images/logo.png"
MAC_ICON_SET = (
    PROJECT_ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
)
WINDOWS_ICON_PATH = PROJECT_ROOT / "windows/runner/resources/app_icon.ico"

MAC_SIZES = {
    "app_icon_16.png": 16,
    "app_icon_32.png": 32,
    "app_icon_64.png": 64,
    "app_icon_128.png": 128,
    "app_icon_256.png": 256,
    "app_icon_512.png": 512,
    "app_icon_1024.png": 1024,
}

WINDOWS_SIZES = [16, 24, 32, 48, 64, 128, 256]


def run(command: list[str]) -> None:
    subprocess.run(
        command,
        check=True,
        cwd=PROJECT_ROOT,
        stdout=subprocess.DEVNULL,
    )


def require_tool(name: str) -> None:
    if shutil.which(name) is None:
        raise SystemExit(f"Required tool not found: {name}")


def write_mac_contents_json() -> None:
    contents = """{
  "images" : [
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "app_icon_16.png",
      "scale" : "1x"
    },
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "app_icon_32.png",
      "scale" : "2x"
    },
    {
      "size" : "32x32",
      "idiom" : "mac",
      "filename" : "app_icon_32.png",
      "scale" : "1x"
    },
    {
      "size" : "32x32",
      "idiom" : "mac",
      "filename" : "app_icon_64.png",
      "scale" : "2x"
    },
    {
      "size" : "128x128",
      "idiom" : "mac",
      "filename" : "app_icon_128.png",
      "scale" : "1x"
    },
    {
      "size" : "128x128",
      "idiom" : "mac",
      "filename" : "app_icon_256.png",
      "scale" : "2x"
    },
    {
      "size" : "256x256",
      "idiom" : "mac",
      "filename" : "app_icon_256.png",
      "scale" : "1x"
    },
    {
      "size" : "256x256",
      "idiom" : "mac",
      "filename" : "app_icon_512.png",
      "scale" : "2x"
    },
    {
      "size" : "512x512",
      "idiom" : "mac",
      "filename" : "app_icon_512.png",
      "scale" : "1x"
    },
    {
      "size" : "512x512",
      "idiom" : "mac",
      "filename" : "app_icon_1024.png",
      "scale" : "2x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
"""
    (MAC_ICON_SET / "Contents.json").write_text(contents, encoding="utf-8")


def generate_macos_icons() -> None:
    MAC_ICON_SET.mkdir(parents=True, exist_ok=True)
    for filename, size in MAC_SIZES.items():
        run(
            [
                "sips",
                "-z",
                str(size),
                str(size),
                str(LOGO_PATH),
                "--out",
                str(MAC_ICON_SET / filename),
            ]
        )
    write_mac_contents_json()

    with tempfile.TemporaryDirectory() as temp_dir:
        iconset = Path(temp_dir) / "AppIcon.iconset"
        iconset.mkdir()
        icon_map = {
            "icon_16x16.png": 16,
            "icon_16x16@2x.png": 32,
            "icon_32x32.png": 32,
            "icon_32x32@2x.png": 64,
            "icon_128x128.png": 128,
            "icon_128x128@2x.png": 256,
            "icon_256x256.png": 256,
            "icon_256x256@2x.png": 512,
            "icon_512x512.png": 512,
            "icon_512x512@2x.png": 1024,
        }
        for filename, size in icon_map.items():
            run(
                [
                    "sips",
                    "-z",
                    str(size),
                    str(size),
                    str(LOGO_PATH),
                    "--out",
                    str(iconset / filename),
                ]
            )
        run(
            [
                "iconutil",
                "-c",
                "icns",
                str(iconset),
                "-o",
                str(MAC_ICON_SET / "AppIcon.icns"),
            ]
        )


def generate_png(size: int, output_path: Path) -> None:
    run(
        [
            "sips",
            "-z",
            str(size),
            str(size),
            str(LOGO_PATH),
            "--out",
            str(output_path),
        ]
    )


def build_ico(png_paths: list[Path], output_path: Path) -> None:
    images = [path.read_bytes() for path in png_paths]
    header = struct.pack("<HHH", 0, 1, len(images))
    directory = bytearray()
    offset = 6 + 16 * len(images)

    for path, image in zip(png_paths, images):
        size = int(path.stem.split("_")[-1])
        width = 0 if size >= 256 else size
        height = 0 if size >= 256 else size
        directory.extend(
            struct.pack(
                "<BBBBHHII",
                width,
                height,
                0,
                0,
                1,
                32,
                len(image),
                offset,
            )
        )
        offset += len(image)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("wb") as file:
        file.write(header)
        file.write(directory)
        for image in images:
            file.write(image)


def generate_windows_icon() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        png_paths = []
        for size in WINDOWS_SIZES:
            path = Path(temp_dir) / f"icon_{size}.png"
            generate_png(size, path)
            png_paths.append(path)
        build_ico(png_paths, WINDOWS_ICON_PATH)


def main() -> None:
    if not LOGO_PATH.exists():
        raise SystemExit(f"Logo not found: {LOGO_PATH}")

    require_tool("sips")
    require_tool("iconutil")

    generate_macos_icons()
    generate_windows_icon()

    print(f"Generated macOS icons: {MAC_ICON_SET}")
    print(f"Generated Windows icon: {WINDOWS_ICON_PATH}")


if __name__ == "__main__":
    os.environ.setdefault("LC_ALL", "C")
    main()
