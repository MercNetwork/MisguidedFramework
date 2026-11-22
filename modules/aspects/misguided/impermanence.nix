# misguided.impermanence — "erase your darlings" for the NixOS hosts.
#
# Every boot, before / is mounted, the Btrfs @ subvolume is moved to
# /old_roots/<timestamp> (on the top-level volume) and a fresh, empty @ is
# created. Old roots older than settings.misguided.impermanence.keepDays are
# deleted. /nix, /home, /persist, /swap and any extra subvolume are untouched.
#
# What survives a reboot is what some aspect lists under `persist`:
#
#   misguided.tailscale.persist.directories = [ "/var/lib/tailscale" ];
#
# The collector below gathers every `persist` entry of every aspect the host
# includes into environment.persistence."/persist". Adding an aspect to a host
# adds its paths; removing it removes them. Aspects don't need to know whether
# the host is impermanent: on a host without this aspect the list is ignored.
#
# Home directories are NOT wiped (@home is its own subvolume). See the
# migration guide for turning on home impermanence later.
{
  inputs,
  lib,
  misguided,
  ...
}:
{
  flake-file.inputs.impermanence = {
    url = "github:nix-community/impermanence";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  den.quirks.persist.description = "System paths kept on /persist across reboots (impermanence)";

  misguided.impermanence = {
    settings = {
      wipeRootOnBoot = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Recreate the @ subvolume on every boot. Set false while migrating a host:
          persistence bind mounts are active but nothing is deleted yet.
        '';
      };

      keepDays = lib.mkOption {
        type = lib.types.ints.positive;
        default = 30;
        description = "Keep wiped roots in /old_roots this many days (recover forgotten files from there).";
      };
    };

    includes = [
      misguided.impermanence.collect
      misguided.impermanence.rollback
    ];

    # Paths every NixOS machine needs to stay itself.
    persist = {
      directories = [
        "/var/lib/nixos" # uid/gid allocations — without it users can change ids
        "/var/lib/systemd" # timers, random seed, credential.secret, backlight, rfkill
        "/var/log"
        {
          directory = "/var/db/sudo";
          mode = "0711";
        }
      ];
      files = [
        "/etc/machine-id" # journald files are keyed by it
        # Written by misguided-install to /persist; sops-nix decrypts with it.
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
      ];
    };

    nixos =
      { host, ... }:
      {
        imports = [ inputs.impermanence.nixosModules.impermanence ];

        assertions = [
          {
            assertion = host.hasAspect misguided.disk;
            message = "misguided.impermanence needs misguided.disk (the Btrfs @ / @persist layout) on ${host.name}.";
          }
        ];

        environment.persistence."/persist".hideMounts = true;

        # impermanence can create /var/lib and /var/lib/private with modes that
        # systemd's DynamicUser services (AdGuard Home…) refuse.
        system.activationScripts.misguided-var-lib-modes = {
          deps = [ "createPersistentStorageDirs" ];
          text = ''
            chmod 0755 /var/lib
            if [ -d /var/lib/private ]; then chmod 0700 /var/lib/private; fi
          '';
        };
      };

    collect.nixos =
      { persist, ... }:
      {
        environment.persistence."/persist" = {
          directories = lib.unique (lib.concatMap (e: e.directories or [ ]) persist);
          files = lib.unique (lib.concatMap (e: e.files or [ ]) persist);
        };
      };

    rollback.nixos =
      { host, pkgs, ... }:
      let
        cfg = host.settings.misguided.impermanence;
        rootDevice = "dev-disk-by\\x2dlabel-Nixos\\x2droot.device";
      in
      {
        config = lib.mkIf cfg.wipeRootOnBoot {
          # (NixOS 26.11+ always uses the systemd initrd, which this unit needs.)
          boot.initrd.systemd.initrdBin = [ pkgs.findutils ];

          boot.initrd.systemd.services.misguided-wipe-root = {
            description = "Recreate the Btrfs @ root subvolume (impermanence)";
            wantedBy = [ "initrd.target" ];
            # Waits for the label, which only appears after LUKS is unlocked.
            requires = [ rootDevice ];
            after = [ rootDevice ];
            before = [ "sysroot.mount" ];
            unitConfig.DefaultDependencies = "no";
            serviceConfig.Type = "oneshot";
            script = ''
              mkdir -p /btrfs_tmp
              mount -t btrfs -o subvol=/ /dev/disk/by-label/Nixos-root /btrfs_tmp

              if [ -e /btrfs_tmp/@ ]; then
                mkdir -p /btrfs_tmp/old_roots
                timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/@)" "+%Y-%m-%d_%H-%M-%S")
                mv /btrfs_tmp/@ "/btrfs_tmp/old_roots/$timestamp"
              fi

              delete_subvolume_recursively() {
                IFS=$'\n'
                for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                  delete_subvolume_recursively "/btrfs_tmp/$i"
                done
                btrfs subvolume delete "$1"
              }

              for i in $(find /btrfs_tmp/old_roots/ -mindepth 1 -maxdepth 1 -mtime +${toString cfg.keepDays}); do
                delete_subvolume_recursively "$i"
              done

              btrfs subvolume create /btrfs_tmp/@
              umount /btrfs_tmp
            '';
          };
        };
      };
  };
}
