# Caddy web server / reverse proxy, driven by a Caddyfile kept in the repo
# (Metyr uses hosts/Metyr/Caddyfile). Edit it, then `mcli switch` (Caddy reloads
# without dropping connections).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.misguided.services.caddy;
in {
  options.misguided.services.caddy = {
    enable = lib.mkEnableOption "Caddy web server and reverse proxy";

    configFile = lib.mkOption {
      type = lib.types.path;
      description = "Caddyfile to run.";
      example = lib.literalExpression "./Caddyfile";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open HTTP (80) and HTTPS (443).";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.caddy];

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [80 443];

    services.caddy = {
      enable = true;
      inherit (cfg) configFile;
      adapter = "caddyfile";
    };
  };
}
