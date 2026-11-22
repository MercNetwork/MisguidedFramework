# misguided.cloudflared — Cloudflare Tunnel, as two choices:
#
#   misguided.cloudflared.client   only the `cloudflared` CLI
#   misguided.cloudflared.server   run a tunnel; needs misguided.sops and
#                                  settings.misguided.cloudflared.server.{tunnelId,credentialsFile}
#                                  (credentials JSON encrypted with sops)
{ lib, misguided, ... }:
let
  cli.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.cloudflared ];
    };
in
{
  misguided.cloudflared = {
    client = cli;

    server = {
      includes = [ cli ];

      settings = {
        tunnelId = lib.mkOption {
          type = lib.types.str;
          description = "Cloudflare Tunnel UUID for this machine.";
        };
        credentialsFile = lib.mkOption {
          type = lib.types.path;
          description = "sops-encrypted tunnel credentials (JSON).";
        };
        defaultService = lib.mkOption {
          type = lib.types.str;
          default = "http_status:404";
          description = "Fallback service when no ingress rule matches.";
        };
      };

      nixos =
        { host, ... }:
        let
          cfg = host.settings.misguided.cloudflared.server;
        in
        {
          assertions = [
            {
              assertion = host.hasAspect misguided.sops;
              message = "misguided.cloudflared.server needs misguided.sops on ${host.name}.";
            }
          ];

          sops.secrets.${cfg.tunnelId} = {
            sopsFile = cfg.credentialsFile;
            format = "json";
            mode = "0444";
            path = "/run/secrets/${cfg.tunnelId}";
          };

          services.cloudflared = {
            enable = true;
            tunnels.${cfg.tunnelId} = {
              credentialsFile = "/run/secrets/${cfg.tunnelId}";
              default = cfg.defaultService;
            };
          };
        };
    };
  };
}
