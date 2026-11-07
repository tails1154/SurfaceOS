#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$ROOT_DIR/profile"
OUT_DIR="$ROOT_DIR/out"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root: sudo ./build.sh" >&2
  exit 1
fi

command -v mkarchiso >/dev/null || {
  echo "mkarchiso is required. Install it with: pacman -S archiso" >&2
  exit 1
}

mkdir -p "$OUT_DIR"
rm -rf "$OUT_DIR"/*
mkarchiso -v -w /tmp/surfaceos-work -o "$OUT_DIR" "$PROFILE_DIR"
