# misguided.tailscale — on every NixOS machine (included by misguided.base).
#
# First time on each machine:   sudo tailscale up
# (or set services.tailscale.authKeyFile on a headless box, e.g. a sops secret).
# The node key lives in /var/lib/tailscale, persisted below, so an impermanent
# machine stays logged in.
#
# tailscale0 is a trusted interface: anything on your tailnet — your iPhone
# included — reaches every port on the machine (SSH, Remote Desktop, Immich,
# Jellyfin, Transmission…) without opening those ports to the LAN or internet.
# With MagicDNS on (admin console → DNS), hosts answer as romina, midra,
# metyr, malenia, rellana.
#
# Exit node / subnet router (e.g. Metyr for your phone): in that host's nixos
# block set services.tailscale.useRoutingFeatures = "server";
{
  misguided.tailscale = {
    persist.directories = [ "/var/lib/tailscale" ];

    nixos =
      { config, lib, ... }:
      {
        services.tailscale = {
          enable = true;
          port = lib.mkDefault 41641; # UDP; direct connections instead of relays
          useRoutingFeatures = lib.mkDefault "none";
        };

        networking.firewall = {
          trustedInterfaces = [ "tailscale0" ];
          allowedUDPPorts = [ config.services.tailscale.port ];
        };
      };
  };
}
