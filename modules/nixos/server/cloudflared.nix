# Cloudflare Tunnel. role = "server" runs a tunnel (needs sops-nix and the
# tunnel credentials JSON encrypted with sops); "client" only installs the CLI.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.misguided.services.cloudflared;
in {
  options.misguided.services.cloudflared = {
    role = lib.mkOption {
      type = lib.types.enum ["none" "client" "server"];
      default = "none";
      description = "server (run tunnel), client (CLI only), or none.";
    };

    tunnelId = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Cloudflare Tunnel UUID for this machine.";
    };

    credentialsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "sops-encrypted tunnel credentials (JSON).";
    };

    defaultService = lib.mkOption {
      type = lib.types.str;
      default = "http_status:404";
      description = "Fallback service when no ingress rule matches.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.role == "server") {
      assertions = [
        {
          assertion = cfg.tunnelId != "" && cfg.credentialsFile != null;
          message = "misguided.services.cloudflared: set tunnelId and credentialsFile when role = \"server\".";
        }
        {
          assertion = config.misguided.security.sops.enable;
          message = "misguided.services.cloudflared: role = \"server\" needs misguided.security.sops.enable.";
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
    })

    (lib.mkIf (cfg.role != "none") {
      environment.systemPackages = [pkgs.cloudflared];
    })
  ];
}
