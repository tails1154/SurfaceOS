#!/usr/bin/env bash
set -euo pipefail

# Run this from the official Arch ISO. It intentionally refuses USB targets.
# Usage: sudo ./install-surfaceos.sh

if [[ ${EUID} -ne 0 ]]; then exec sudo -E "$0" "$@"; fi
command -v dialog >/dev/null || { echo "dialog is required on the Arch ISO." >&2; exit 1; }

export DIALOGRC=/dev/null
die() { dialog --title 'SurfaceOS installer' --msgbox "$1" 8 70; clear; exit 1; }
cancelled() { dialog --title 'SurfaceOS installer' --msgbox 'Installation cancelled.' 7 50; clear; exit 1; }

mapfile -t disks < <(lsblk -dpno NAME,MODEL,SIZE,TRAN,TYPE | awk '$4 != "usb" && $5 == "disk" {print}')
(( ${#disks[@]} )) || die 'No internal disk was detected.'
menu_args=()
for line in "${disks[@]}"; do
  name=${line%% *}; label=${line#* }
  menu_args+=("$name" "$label")
done
target=$(dialog --stdout --title 'Select internal disk' --menu \
  'Choose the disk to erase and install SurfaceOS onto:' 15 90 6 "${menu_args[@]}") || cancelled
target=$(readlink -f -- "$target")

target="$(readlink -f -- "$target")"
[[ -b "$target" ]] || die "Not a block device: $target"
[[ "$(lsblk -dn -o TYPE "$target")" == disk ]] || die 'The selected target is not a whole disk.'
[[ "$(lsblk -dn -o TRAN "$target")" != usb ]] || die 'USB disks are refused. Select the Surface internal disk.'

case "$target" in
  /dev/nvme*|/dev/mmcblk*) part_prefix="${target}p" ;;
  *) part_prefix="$target" ;;
esac
efi="${part_prefix}1"
root="${part_prefix}2"

model=$(lsblk -dn -o MODEL,SIZE "$target")
dialog --title 'FINAL WARNING' --yesno "This permanently erases:\n\n$target ($model)\n\nAll existing data will be destroyed. Continue?" 12 70 || cancelled

gauge() {
  local title=$1; shift
  dialog --title 'SurfaceOS installer' --gauge "$title" 8 70 0 &
  local dialog_pid=$!
  "$@" >/tmp/surfaceos-install.log 2>&1 || { kill "$dialog_pid" 2>/dev/null || true; wait "$dialog_pid" 2>/dev/null || true; die "Step failed. See /tmp/surfaceos-install.log on the live system."; }
  kill "$dialog_pid" 2>/dev/null || true
  wait "$dialog_pid" 2>/dev/null || true
}

for part in $(lsblk -nr -o NAME "$target" | tail -n +2); do
  umount -R "/dev/$part" 2>/dev/null || true
done

gauge 'Partitioning the Surface internal disk...' sgdisk --zap-all "$target"
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:EFI \
       -n 2:0:0    -t 2:8300 -c 2:SurfaceOS "$target" >/tmp/surfaceos-install.log 2>&1 || die 'Partitioning failed.'
partprobe "$target"
udevadm settle

gauge 'Formatting the EFI partition...' mkfs.fat -F32 -n SURFACE_EFI "$efi"
gauge 'Formatting the SurfaceOS partition...' mkfs.ext4 -F -L SurfaceOS "$root"
mount "$root" /mnt
mkdir -p /mnt/boot
mount "$efi" /mnt/boot

dialog --infobox 'Installing the SurfaceOS package set. This may take a while...' 6 70
pacstrap -K /mnt \
  base linux linux-firmware linux-firmware-marvell intel-ucode mkinitcpio \
  networkmanager sudo polkit plasma-desktop plasma-nm plasma-pa \
  plasma-workspace plasma-systemmonitor systemsettings sddm \
  xorg-server xorg-xinit xorg-xinput xf86-input-libinput mesa vulkan-intel \
  libva-intel-driver pipewire pipewire-pulse wireplumber bluez bluez-utils \
  power-profiles-daemon iio-sensor-proxy upower fwupd grub efibootmgr \
  dosfstools e2fsprogs btrfs-progs kdialog konsole dolphin firefox ark \
  unzip git vim htop dialog >/tmp/surfaceos-install.log 2>&1 || die 'Package installation failed.'

genfstab -U /mnt >> /mnt/etc/fstab

username=$(dialog --stdout --title 'Create user' --inputbox 'New SurfaceOS username:' 8 60 'surface') || cancelled
user_password=$(dialog --stdout --title 'Create user' --passwordbox "Password for $username:" 8 60) || cancelled
root_password=$(dialog --stdout --title 'Root password' --passwordbox 'Root password:' 8 60) || cancelled

install -d -m 0755 /mnt/etc/modules-load.d /mnt/etc/sudoers.d
printf 'mwifiex_usb\n' > /mnt/etc/modules-load.d/surface-wifi.conf
printf '%%wheel ALL=(ALL:ALL) ALL\n' > /mnt/etc/sudoers.d/10-wheel
chmod 0440 /mnt/etc/sudoers.d/10-wheel
printf 'SurfaceOS\n' > /mnt/etc/hostname

arch-chroot /mnt /bin/bash -e <<CHROOT
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf
printf 'KEYMAP=us\n' > /etc/vconsole.conf
printf 'SurfaceOS\n' > /etc/hostname

sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=SurfaceOS --recheck "$target"
grub-mkconfig -o /boot/grub/grub.cfg

useradd -m -G wheel -s /bin/bash '$username'
printf '%s:%s\n' '$username' '$user_password' | chpasswd
printf 'root:%s\n' '$root_password' | chpasswd
systemctl enable NetworkManager sddm bluetooth power-profiles-daemon
systemctl enable systemd-timesyncd
CHROOT

umount -R /mnt
dialog --title 'SurfaceOS installation complete' --msgbox "SurfaceOS was installed on $target.\n\nReboot and remove the Arch USB." 8 70
clear
