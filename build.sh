#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
profile_dir="$root_dir/profile"
out_dir="$root_dir/out"
pkg_dir="$out_dir/packages"

[[ ${EUID} -eq 0 ]] || { echo 'Run with sudo: sudo ./build.sh' >&2; exit 1; }
command -v mkarchiso >/dev/null || { echo 'archiso is required.' >&2; exit 1; }
calamares_pkg=$(find "$pkg_dir" -maxdepth 1 -type f -name 'calamares-[0-9]*.pkg.tar.zst' -print -quit)
[[ -n "$calamares_pkg" ]] || { echo 'Prebuilt Calamares package is missing from out/packages.' >&2; exit 1; }

repo-add "$pkg_dir/surfaceos.db.tar.gz" "$calamares_pkg"
mkdir -p "$out_dir"
if [[ -d "$out_dir/work" ]]; then
  while IFS= read -r mountpoint; do
    umount --lazy "$mountpoint" 2>/dev/null || true
  done < <(findmnt --recursive --noheadings --output TARGET "$out_dir/work" 2>/dev/null | sort --reverse)
  rm -rf -- "$out_dir/work"
fi
rm -f -- "$out_dir/surfaceos-"*.iso "$out_dir/surfaceos-"*.iso.* 2>/dev/null || true
mkarchiso -v -w "$out_dir/work" -o "$out_dir" "$profile_dir"
