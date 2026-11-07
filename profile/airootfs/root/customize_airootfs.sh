#!/usr/bin/env bash
set -e

useradd -m -G wheel,audio,video,storage,network -s /bin/bash liveuser
passwd -d liveuser
install -d -m 0755 /usr/share/surfaceos/installer
install -m 0644 /installer/user_configuration.json /usr/share/surfaceos/installer/user_configuration.json

systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable sddm.service
systemctl enable surfaceos-firstboot.service

rm -f /etc/machine-id
truncate -s 0 /etc/hostname
