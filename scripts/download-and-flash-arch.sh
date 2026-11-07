#!/usr/bin/env bash
set -euo pipefail

# Downloads the official Arch ISO, verifies its SHA-256, and writes it to a
# selected USB disk. This utility is fully TUI-based.

if [[ ${EUID} -ne 0 ]]; then exec sudo -E "$0" "$@"; fi
command -v dialog >/dev/null || { echo "dialog is required." >&2; exit 1; }
export DIALOGRC=/dev/null
die() { dialog --title 'Arch USB writer' --msgbox "$1" 8 70; clear; exit 1; }
mapfile -t disks < <(lsblk -dpno NAME,MODEL,SIZE,TRAN,TYPE | awk '$4 == "usb" && $5 == "disk" {print}')
((${#disks[@]})) || die 'No USB disk was detected.'
menu_args=()
for line in "${disks[@]}"; do name=${line%% *}; label=${line#* }; menu_args+=("$name" "$label"); done
target=$(dialog --stdout --title 'Select USB installer disk' --menu 'Choose the USB disk to erase:' 15 90 6 "${menu_args[@]}") || exit 1
target=$(readlink -f -- "$target")

version=2026.11.01
filename="archlinux-${version}-x86_64.iso"
sha256=01bcdcf01af2f7d58f279489c9c834eea6da233f557364821f13d12c2b0a9059a5
url="https://geo.mirror.pkgbuild.com/iso/${version}/${filename}"
out="${XDG_CACHE_HOME:-/var/cache}/surfaceos-${filename}"

model=$(lsblk -dn -o MODEL,SIZE "$target")
dialog --title 'FINAL WARNING' --yesno "This permanently erases:\n\n$target ($model)\n\nContinue?" 11 70 || exit 1

mkdir -p "$(dirname "$out")"
set -o pipefail
curl -fL --retry 3 --progress-bar -o "$out" "$url" 2>&1 | \
  tr '\r' '\n' | sed -n 's/.*\([0-9][0-9]*\)%.*/\1/p' | \
  dialog --title 'Downloading Arch ISO' --gauge 'Downloading the official Arch ISO...' 8 70 0 || \
  die 'Arch ISO download failed.'
dialog --title 'Arch ISO download' --gauge 'Arch ISO downloaded. Verifying SHA-256...' 8 70 70 & gauge_pid=$!
printf '%s  %s\n' "$sha256" "$out" | sha256sum -c >/tmp/surfaceos-verify.log 2>&1 || { kill "$gauge_pid" 2>/dev/null || true; die 'Arch ISO checksum verification failed.'; }
kill "$gauge_pid" 2>/dev/null || true
umount -R "$target" 2>/dev/null || true
total=$(stat -c '%s' "$out")
dd if="$out" of="$target" bs=4M status=progress conv=fsync 2>&1 | \
  awk -v total="$total" '/bytes/ {printf "%d\n", ($1/total)*100; fflush()}' | \
  dialog --title 'Writing Arch ISO' --gauge 'Flashing Arch ISO to USB...' 8 70 0
sync
dialog --title 'Complete' --msgbox "Arch ISO verified and written to $target.\n\nBoot the Surface from this USB and run the SurfaceOS installer." 9 70
clear
