#!/usr/bin/env bash
iso_name="surfaceos"
iso_label="SURFACEOS_$(date +%Y%m)"
iso_publisher="SurfaceOS contributors"
iso_application="SurfaceOS — Arch Linux for Surface Pro 2"
iso_version="0.1.0"
install_dir="arch"
buildmodes=("iso")
bootmodes=('uefi-x64.grub.esp')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
file_permissions=(
  ["/etc/sudoers.d/live-user"]="0:0:440"
  ["/usr/local/bin/surface-installer"]="0:0:755"
  ["/usr/local/bin/surfaceos-live-setup"]="0:0:755"
)
