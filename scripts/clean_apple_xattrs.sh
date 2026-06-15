#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ "$(uname -s)" != "Darwin" ]]; then
  exit 0
fi

targets=(
  ios
  macos
  assets
  lib
  pubspec.yaml
  build/ios
  build/macos
)

for target in "${targets[@]}"; do
  if [[ -e "$target" ]]; then
    xattr -cr "$target" 2>/dev/null || true
    xattr -dr com.apple.FinderInfo "$target" 2>/dev/null || true
    xattr -dr com.apple.ResourceFork "$target" 2>/dev/null || true
    xattr -dr com.apple.fileprovider.fpfs#P "$target" 2>/dev/null || true
    xattr -dr com.apple.fileprovider.dir#N "$target" 2>/dev/null || true
    xattr -dr com.apple.provenance "$target" 2>/dev/null || true
  fi
done
