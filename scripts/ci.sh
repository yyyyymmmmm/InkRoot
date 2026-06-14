#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MODE="${1:-all}"

case "$MODE" in
  all|android|android-debug|android-release|ios|ios-sim|ios-unsigned-ipa|macos|macos-debug|macos-release|windows|windows-debug|windows-release|linux|linux-debug|linux-release|web|web-release)
    ;;
  *)
    echo "Usage: scripts/ci.sh [all|android-debug|android-release|ios-sim|ios-unsigned-ipa|macos-debug|macos-release|windows-debug|windows-release|linux-debug|linux-release|web-release]" >&2
    exit 2
    ;;
esac

case "$MODE" in
  ios) MODE="ios-sim" ;;
  macos) MODE="macos-debug" ;;
  windows) MODE="windows-debug" ;;
  linux) MODE="linux-debug" ;;
  web) MODE="web-release" ;;
  android) MODE="android-debug" ;;
esac

dart tool/inkroot.dart ci "$MODE"
