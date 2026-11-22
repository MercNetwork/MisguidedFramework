# misguided.caddy — Caddy web server / reverse proxy. The host points it at a
# Caddyfile kept in the repo (Metyr: services.caddy.configFile = ./Caddyfile).
# Edit it, then `mcli switch` (Caddy reloads without dropping connections).
{
  misguided.caddy = {
    # Certificates, Caddy's internal CA (`tls internal`), autosave.json.
    persist.directories = [ "/var/lib/caddy" ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.caddy ];
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];
        services.caddy = {
          enable = true;
          adapter = "caddyfile";
        };
      };
  };
}
