# Tailscale mesh VPN. Authenticate once with `sudo tailscale up`.
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
      description = "UDP port Tailscale listens on.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the Tailscale UDP port in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      inherit (cfg) port;
    };

    networking.firewall = {
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = lib.mkIf cfg.openFirewall [cfg.port];
    };
  };
}
