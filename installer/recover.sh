#!/usr/bin/env bash
set -euo pipefail

# misguided-recover — mount an installed Misguided Framework system at /mnt for repair.
#
#   sudo misguided-recover            # auto-detect (unlocks LUKS if needed)
#   sudo misguided-recover /dev/...   # explicit Btrfs device
#   sudo nixos-enter               # then work inside the system

ROOT_DEV="${1:-}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: misguided-recover must be run as root (or via sudo)." >&2
  exit 1
fi

# Unlock the encrypted root if it isn't open yet (Disko partition label "luks")
if [ -z "${ROOT_DEV}" ] && [ ! -e /dev/mapper/cryptroot ] && [ -e /dev/disk/by-partlabel/luks ]; then
  echo "--> Unlocking /dev/disk/by-partlabel/luks as cryptroot..."
  cryptsetup open /dev/disk/by-partlabel/luks cryptroot
fi

# Auto-detect root device if not explicitly provided
if [ -z "${ROOT_DEV}" ]; then
  if [ -e "/dev/mapper/cryptroot" ]; then
    ROOT_DEV="/dev/mapper/cryptroot"
  elif [ -e "/dev/disk/by-label/Nixos-root" ]; then
    ROOT_DEV="/dev/disk/by-label/Nixos-root"
  else
    echo "Error: Could not automatically detect root block device." >&2
    echo "Please specify the root device: misguided-recover <root-device>" >&2
    echo "Examples:" >&2
    echo "  misguided-recover /dev/mapper/cryptroot" >&2
    echo "  misguided-recover /dev/disk/by-label/Nixos-root" >&2
    exit 1
  fi
fi

echo "--> Target root device: ${ROOT_DEV}"

# 1. Clean up existing mounts
echo "--> Cleaning up existing /mnt mounts..."
umount -R /mnt 2>/dev/null || true

# 2. Mount the root subvolume
echo "--> Mounting root subvolume '@' to /mnt..."
mount -o subvol=@ "${ROOT_DEV}" /mnt

# 3. Mount the other subvolumes (skipping any this host doesn't have)
echo "--> Mounting subvolumes..."
for pair in "@nix:/nix" "@home:/home" "@persist:/persist" "@services:/mnt/services"; do
  subvol="${pair%%:*}"
  target="/mnt${pair#*:}"
  mkdir -p "${target}"
  mount -o "subvol=${subvol}" "${ROOT_DEV}" "${target}" 2>/dev/null ||
    echo "    (no ${subvol} subvolume, skipped)"
done

# 4. Detect and mount boot partition
BOOT_DEV=""
if [ -e "/dev/disk/by-label/Nixos-boot" ]; then
  BOOT_DEV="/dev/disk/by-label/Nixos-boot"
elif [ -e "/dev/disk/by-partlabel/boot" ]; then
  BOOT_DEV="/dev/disk/by-partlabel/boot"
fi

if [ -n "${BOOT_DEV}" ]; then
  echo "--> Mounting EFI boot partition (${BOOT_DEV}) to /mnt/boot..."
  mkdir -p /mnt/boot
  mount "${BOOT_DEV}" /mnt/boot
else
  echo "Warning: Could not auto-detect boot partition. Mount it manually to /mnt/boot if needed." >&2
fi

echo "=================================================="
echo "--> Misguided Framework system mounted at /mnt."
echo "Run 'nixos-enter' to access your system environment."
echo "Impermanent hosts: / is fresh every boot. Files from earlier boots are in"
echo "the old_roots/<timestamp> subvolumes:  mount -o subvol=/ ${ROOT_DEV} /mnt2"
echo "=================================================="
