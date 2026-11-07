# SurfaceOS

SurfaceOS is a small Arch Linux distribution profile for the Microsoft Surface Pro 2. It keeps the system light enough for the 4 GB model while giving the tablet a calm, macOS-inspired layout: a top bar, centered launcher dock, familiar keyboard shortcuts, and touch-friendly defaults.

This is an original Linux desktop configuration, not macOS and not a redistribution of Apple software or artwork. The visual direction takes cues from the layout of pearOS, but SurfaceOS owns its theme, name, icons, and configuration.

## Hardware target

The profile is tuned for the Surface Pro 2's 4th-generation Intel Core i5-4200U, Intel HD Graphics 4400, 4 or 8 GB LPDDR3, 10.6-inch 1920×1080 10-point touchscreen, 802.11a/b/g/n Wi-Fi, Bluetooth 4.0, cameras, ambient sensors, USB 3.0, microSD, and Mini DisplayPort.

The GPU uses the in-kernel `i915` driver. The profile deliberately uses X11 Plasma instead of requiring newer Wayland tablet support, and includes `linux-surface` as an optional post-install choice for pen/touch improvements.

## Build a bootable ISO

Build on an Arch Linux host or an Arch container with `archiso` installed:

```sh
sudo pacman -S --needed archiso git
git clone <this-repository> surfaceos
cd surfaceos
sudo ./build.sh
```

The output is written to `out/`. Write it to a USB drive only after checking the device path:

```sh
sudo dd if=out/SurfaceOS-0.1.0-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

The live image boots into the SurfaceOS desktop with **Surface Installer** in the application launcher. It opens Calamares, which partitions the chosen drive, copies the live root filesystem, configures the installed system, and installs GRUB for UEFI boot.

## Design choices

- Plasma is used because it provides a reliable global panel, touch-capable input stack, and a cohesive theming surface; the package set avoids heavy effects.
- The theme uses a cool graphite/indigo palette and a simple Surface-inspired mark instead of Apple marks or bundled Apple artwork.
- `thermald`, `tlp`, `power-profiles-daemon`, and `iio-sensor-proxy` cover battery, thermal, and orientation behavior.
- `xf86-input-libinput`, `libinput`, and `xorg-xinput` keep touch and Type Cover behavior inspectable and easy to debug.

## Known limits

This repository creates a reproducible starting point; it cannot test every revision of the old Surface firmware. Wi-Fi firmware, cameras, the Type Cover, pen, and sensors should be verified from the live ISO before installing. If `linux-surface` is needed, enable its repository and install its kernel after the base system is working.

## References

- [Microsoft Surface Pro 2 specifications](https://support.microsoft.com/en-us/surface/models/surface-pro-2-specs-and-features)
- [PearOS documentation](https://pearos-archlinux.github.io/pearOS-documentation/)
