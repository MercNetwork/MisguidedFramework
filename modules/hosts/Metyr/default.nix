# Metyr (formerly Morgott) — homelab / self-hosting server, headless.
# Ports (open on the LAN + Tailscale):
#   80/443 Caddy · 53 + 9998 AdGuard Home · 2283 Immich · 8096 Jellyfin
#   9091 Transmission (Fragments on the desktops) · 8384 Syncthing UI (localhost only)
#   22 SSH (keys only)
# Service data lives on the @services subvolume at /mnt/services (kept across
# reboots); the rest of / is wiped by misguided.impermanence.
{ misguided, ... }:
{
  den.hosts.x86_64-linux.Metyr.settings.misguided = {
    disk = {
      device = "/dev/nvme0n1"; # a SATA disk is /dev/sda
      # No disk encryption: a headless server can't type a passphrase after a power cut.
      encrypt = false;
      # For a separate data disk, move this onto a second disko.devices.disk entry.
      extraSubvolumes."@services" = {
        mountpoint = "/mnt/services";
        mountOptions = [
          "ssd"
          "noatime"
          "compress=zstd"
        ];
      };
    };

    # MIGRATION: dry run — /persist bind mounts on, nothing wiped. Copy state
    # first (guide, Phase B), then delete this line to turn the wipe on.
    impermanence.wipeRootOnBoot = false;

    # adguard.allowedSubnets = [ "192.168.1.0/24" ]; # tighten to your LAN
    # immich.sopsFile = ../../../secrets/metyr.yaml;
    # pgadmin.sopsFile = ../../../secrets/metyr.yaml;
  };

  den.aspects.Metyr = {
    includes = [
      misguided.server
      misguided.disk
      misguided.impermanence

      misguided.caddy
      misguided.adguard
      misguided.syncthing
      misguided.transmission
      misguided.wireguard
      misguided.cloudflared.client # .server once tunnelId + credentialsFile are set

      misguided.podman
      misguided.oci # declarative containers on podman
      misguided.compose2nix
      misguided.immich
      misguided.jellyfin
      # misguided.pgadmin

      misguided.langs.docker # for mercury
    ];

    nixos = {
      imports = [ ./_hardware-configuration.nix ];
      services.caddy.configFile = ./Caddyfile;
      # sops.defaultSopsFile = ../../../secrets/metyr.yaml;
    };
  };
}
