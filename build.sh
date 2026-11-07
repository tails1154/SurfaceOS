#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$ROOT_DIR/profile"
OUT_DIR="$ROOT_DIR/out"
PKG_DIR="$OUT_DIR/packages"
BUILD_DIR="$OUT_DIR/calamares-build"
BUILD_USER="nobody"
TMP_DIR="$OUT_DIR/tmp"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root: sudo ./build.sh" >&2
  exit 1
fi

command -v mkarchiso >/dev/null || {
  echo "mkarchiso is required. Install it with: pacman -S archiso" >&2
  exit 1
}

mkdir -p "$OUT_DIR"
mkdir -p "$PKG_DIR"
mkdir -p "$TMP_DIR"
export TMPDIR="$TMP_DIR"

for tool in git makepkg repo-add runuser; do
  command -v "$tool" >/dev/null || { echo "$tool is required to build Calamares." >&2; exit 1; }
done

if ! compgen -G "$PKG_DIR/calamares-[0-9]*.pkg.tar.zst" >/dev/null; then
  rm -rf "$BUILD_DIR"
  install -d -o "$BUILD_USER" -g "$BUILD_USER" "$BUILD_DIR"
  runuser -u "$BUILD_USER" -- git clone --depth 1 https://aur.archlinux.org/calamares.git "$BUILD_DIR/calamares"
  pacman -S --needed --noconfirm extra-cmake-modules libglvnd ninja qt6-tools qt6-translations kcoreaddons kpmcore libpwquality qt6-declarative qt6-svg yaml-cpp
  runuser -u "$BUILD_USER" -- bash -lc "cd '$BUILD_DIR/calamares' && TMPDIR='$TMP_DIR' makepkg --nodeps --noconfirm --cleanbuild"
  install -m 0644 "$BUILD_DIR"/calamares/*.pkg.tar.zst "$PKG_DIR/"
fi
repo-add "$PKG_DIR/surfaceos.db.tar.gz" "$PKG_DIR"/calamares-[0-9]*.pkg.tar.zst

mkarchiso -v -w "$OUT_DIR/work" -o "$OUT_DIR" "$PROFILE_DIR"
