# Romina disk layout, applied by `misguided-install Romina`. THIS FORMATS THE DISK.
#
#   /dev/nvme0n1  (check with `lsblk` and change `device` below if different)
#   ├─ ESP   1G    vfat   /boot
#   └─ LUKS  rest  -> Btrfs subvolumes:
#        @        /
#        @home    /home
#        @nix     /nix
#        @persist /persist   (host keys written by the installer)
#        @swap    /swap      (16G swapfile)
#
# You'll be asked for the disk-encryption passphrase during install and at
# every boot. To drop encryption, replace the `luks` block with its inner `content`.
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
          label = "luks";
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
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
                "@swap" = {
                  mountpoint = "/swap";
                  mountOptions = ["ssd" "noatime" "nodatacow"];
                  swap.swapfile.size = "16G";
                };
              };
            };
          };
        };
      };
    };
  };
}
