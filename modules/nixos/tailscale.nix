# Tailscale on every NixOS machine (switched on in hosts/common/base.nix).
#
# First time on each machine:   sudo tailscale up
# (or set authKeyFile for a headless box, e.g. a sops secret).
#
# tailscale0 is a trusted interface: anything on your tailnet — your iPhone
# included — reaches every port on the machine (SSH, Remote Desktop, Immich,
# Jellyfin, Transmission…) without opening those ports to the LAN or internet.
# With MagicDNS on (admin console → DNS), hosts answer as romina, midra,
# metyr, malenia, rellana.
{
  config,
  lib,
  ...
}: let
  cfg = config.misguided.services.tailscale;
in {
  options.misguided.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale";

    port = lib.mkOption {
      type = lib.types.port;
      default = 41641;
      description = "UDP port Tailscale listens on (direct connections instead of relays).";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the Tailscale UDP port in the firewall.";
    };

    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/secrets/tailscale-authkey";
      description = "File with a Tailscale auth key, so the machine joins the tailnet on its own.";
    };

    routing = lib.mkOption {
      type = lib.types.enum ["none" "client" "server" "both"];
      default = "none";
      description = ''
        "client" to use other machines' exit nodes / subnet routes,
        "server" to offer them (e.g. Metyr as an exit node for your phone), "both" for both.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      inherit (cfg) port authKeyFile;
      useRoutingFeatures = cfg.routing;
    };

    networking.firewall = {
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = lib.mkIf cfg.openFirewall [cfg.port];
    };
  };
}
