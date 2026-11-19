# Metyr (formerly Morgott) — homelab / self-hosting server, headless.
# The server stack lives here. Ports (open on the LAN + Tailscale):
#   80/443 Caddy · 53 + 9998 AdGuard Home · 2283 Immich · 8096 Jellyfin
#   9091 Transmission (Fragments on the desktops) · 8384 Syncthing UI (localhost only)
#   22 SSH (keys only)
# Service data lives on the @services subvolume at /mnt/services.
{...}: {
  imports = [
    ../common/server.nix
    ./hardware-configuration.nix
    ./disko.nix
  ];

  misguided = {
    services = {
      caddy = {
        enable = true;
        configFile = ./Caddyfile;
      };
      adguard = {
        enable = true;
        # allowedSubnets = ["192.168.1.0/24"];  # tighten to your LAN
      };
      syncthing.enable = true;
      transmission.enable = true;
      wireguard.enable = true;
      cloudflared.role = "client"; # "server" once tunnelId + credentialsFile are set
    };

    virtualisation = {
      podman.enable = true;
      oci.enable = true; # declarative containers on podman
      compose2nix.enable = true;
    };

    oci = {
      immich.enable = true;
      jellyfin.enable = true;
      # pgadmin = {
      #   enable = true;
      #   sopsFile = ../../secrets/metyr.yaml;
      # };
    };

    # security.sops.defaultSopsFile = ../../secrets/metyr.yaml;
  };

  misguided.user.home.misguided.langs.docker.enable = true;
}
