# Malenia disk layout, applied by `mcli deploy Malenia root@<ip>`. THIS FORMATS THE DISK.
#
# Target: an NVMe drive on a Pi 5 NVMe HAT (/dev/nvme0n1) or a USB SSD
# (/dev/sda). It must NOT be the SD card the installer is running from.
#
#   FIRMWARE 1G   vfat   /boot/firmware   (Pi firmware, config.txt, kernel)
#   root     rest btrfs: @ /  @home /home  @nix /nix  @persist /persist
#                        @microvm /var/lib/microvms (guest volumes)  @swap /swap
#
# No disk encryption: a headless Pi can't ask for a passphrase at boot.
# If it won't boot from NVMe, set the EEPROM boot order once from Pi OS:
#   sudo rpi-eeprom-config --edit   ->   BOOT_ORDER=0xf416
{lib, ...}: let
  opts = ["compress=zstd" "noatime"];
in {
  disko.devices.disk.main = {
    device = lib.mkDefault "/dev/nvme0n1";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        FIRMWARE = {
          label = "FIRMWARE";
          priority = 1;
          type = "EF00";
          size = "1G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot/firmware";
            mountOptions = ["noatime" "noauto" "x-systemd.automount" "x-systemd.idle-timeout=1min"];
          };
        };
        root = {
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
                mountOptions = opts;
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = opts;
              };
              "@persist" = {
                mountpoint = "/persist";
                mountOptions = opts;
              };
              # nodatacow: VM disk images fragment badly under copy-on-write
              "@microvm" = {
                mountpoint = "/var/lib/microvms";
                mountOptions = ["noatime" "nodatacow"];
              };
              "@swap" = {
                mountpoint = "/swap";
                swap.swapfile.size = "4G";
              };
            };
          };
        };
      };
    };
  };
}
