# misguided.disk — the ONE disk layout every NixOS host uses (replaces the four
# hosts/<Host>/disko.nix files). Applied by `misguided-install <Host>` or
# `mcli deploy <Host> root@<ip>`. THIS FORMATS THE DISK.
#
#   uefi (Romina, Midra, Metyr)          rpi (Malenia)
#   ├─ ESP  1G vfat /boot                ├─ FIRMWARE 1G vfat /boot/firmware
#   └─ [LUKS cryptroot] -> Btrfs         └─ Btrfs
#
#   Btrfs subvolumes (label Nixos-root):
#     @         /           wiped on every boot by misguided.impermanence
#     @home     /home       kept
#     @nix      /nix        kept
#     @persist  /persist    kept — everything listed under `persist` lives here
#     @swap     /swap       swapfile (settings.misguided.disk.swapSize)
#     + settings.misguided.disk.extraSubvolumes (Metyr's @services, Malenia's @microvm)
#
# Per-host values are settings, set next to the host:
#   den.hosts.x86_64-linux.Romina.settings.misguided.disk = {
#     device = "/dev/nvme0n1";
#     swapSize = "16G";
#   };
{ inputs, lib, ... }:
{
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  misguided.disk = {
    settings = {
      device = lib.mkOption {
        type = lib.types.str;
        example = "/dev/nvme0n1";
        description = "Disk to format. Check with `lsblk` first. No default on purpose.";
      };

      encrypt = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "LUKS-encrypt the Btrfs partition (passphrase at every boot). Off for headless boxes.";
      };

      tpmUnlock = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Unlock LUKS with the machine's TPM chip instead of a passphrase at boot
          (the passphrase keeps working as a fallback). Needs a one-time
          `sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-partlabel/luks`
          on the machine. For machines that stay home: anyone holding the whole
          machine gets to the login screen; the disk alone stays unreadable.
        '';
      };

      boot = lib.mkOption {
        type = lib.types.enum [
          "uefi"
          "rpi"
        ];
        default = "uefi";
        description = ''"uefi": ESP on /boot (systemd-boot). "rpi": Pi firmware partition on /boot/firmware.'';
      };

      swapSize = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "8G";
        description = "Size of /swap/swapfile, or null for no swap.";
      };

      extraSubvolumes = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        example = lib.literalExpression ''
          { "@services" = { mountpoint = "/mnt/services"; mountOptions = [ "noatime" "compress=zstd" ]; }; }
        '';
        description = "More disko Btrfs subvolumes. Their data is kept across reboots (they are not @).";
      };
    };

    nixos =
      { host, ... }:
      let
        cfg = host.settings.misguided.disk;
        uefi = cfg.boot == "uefi";

        ssd = lib.optional uefi "ssd";
        opts = ssd ++ [
          "noatime"
          "compress=zstd"
        ];
        # nodev/nosuid on /home and /nix (the Pi layout never had them).
        hardened =
          opts
          ++ lib.optionals uefi [
            "nodev"
            "nosuid"
          ];

        btrfs = {
          type = "btrfs";
          extraArgs = [
            "-L"
            "Nixos-root"
            "-f"
          ];
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
            # No nodev/nosuid here (the old layout had them): bind mounts inherit
            # them, and /var/lib/containers now lives on /persist.
            "@persist" = {
              mountpoint = "/persist";
              mountOptions = opts;
            };
          }
          // lib.optionalAttrs (cfg.swapSize != null) {
            "@swap" = {
              mountpoint = "/swap";
              mountOptions = ssd ++ [
                "noatime"
                "nodatacow"
              ];
              swap.swapfile.size = cfg.swapSize;
            };
          }
          // cfg.extraSubvolumes;
        };

        root =
          if cfg.encrypt then
            {
              type = "luks";
              name = "cryptroot";
              settings = {
                allowDiscards = true;
              }
              // lib.optionalAttrs cfg.tpmUnlock { crypttabExtraOpts = [ "tpm2-device=auto" ]; };
              content = btrfs;
            }
          else
            btrfs;

        bootPartition =
          if uefi then
            {
              ESP = {
                label = "boot";
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                  extraArgs = [
                    "-n"
                    "Nixos-boot"
                  ];
                };
              };
            }
          else
            {
              FIRMWARE = {
                label = "FIRMWARE";
                priority = 1;
                type = "EF00";
                size = "1G";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot/firmware";
                  mountOptions = [
                    "noatime"
                    "noauto"
                    "x-systemd.automount"
                    "x-systemd.idle-timeout=1min"
                  ];
                };
              };
            };
      in
      {
        imports = [ inputs.disko.nixosModules.disko ];

        disko.devices.disk.main = {
          device = lib.mkDefault cfg.device;
          type = "disk";
          content = {
            type = "gpt";
            partitions = bootPartition // {
              ROOT = {
                # recover.sh unlocks /dev/disk/by-partlabel/luks
                label = if cfg.encrypt then "luks" else "root";
                size = "100%";
                content = root;
              };
            };
          };
        };

        # Impermanence bind-mounts out of /persist during early boot.
        fileSystems."/persist".neededForBoot = true;
      };
  };
}
