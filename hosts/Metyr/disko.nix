# Metyr disk layout, applied by `misguided-install Metyr` (on the box) or
# `mcli deploy Metyr root@<ip>` (from Romina). THIS FORMATS THE DISK.
#
#   /dev/nvme0n1  (check with `lsblk`; a SATA disk is /dev/sda)
#   ├─ ESP   1G    vfat   /boot
#   └─ Btrfs rest:
#        @         /
#        @home     /home
#        @nix      /nix
#        @persist  /persist         (host keys written by the installer)
#        @services /mnt/services    (Immich photos, Jellyfin media/config…)
#        @swap     /swap            (8G swapfile)
#
# No disk encryption: a headless server can't type a passphrase after a power cut.
# For a separate data disk, move @services onto a second `disko.devices.disk` entry.
{lib, ...}: let
  opts = ["ssd" "noatime" "compress=zstd"];
  hardened = opts ++ ["nodev" "nosuid"];
in {
  disko.devices.disk.main = {
    device = lib.mkDefault "/dev/nvme0n1";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          label = "boot";
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
            extraArgs = ["-n" "Nixos-boot"];
          };
        };
        ROOT = {
          label = "root";
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = ["-L" "Nixos-root" "-f"];
            subvolumes = {
              "@" = {
                mountpoint = "/";
                mountOptions = opts;
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = hardened;
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = hardened;
              };
              "@persist" = {
                mountpoint = "/persist";
                mountOptions = hardened;
              };
              "@services" = {
                mountpoint = "/mnt/services";
                mountOptions = opts;
              };
              "@swap" = {
                mountpoint = "/swap";
                mountOptions = ["ssd" "noatime" "nodatacow"];
                swap.swapfile.size = "8G";
              };
            };
          };
        };
      };
    };
  };
}
