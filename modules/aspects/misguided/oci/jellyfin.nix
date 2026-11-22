# misguided.jellyfin — Jellyfin media server in a container. Web UI: http://<host>:8096
# Drop media into /mnt/services/jellyfin/media (and media2, mounted read-only).
# Config and metadata are in /mnt/services/jellyfin/config (the @services
# subvolume), so nothing to persist on the root.
{ lib, misguided, ... }:
let
  base = "/mnt/services/jellyfin";
  tmpDir = "/var/lib/containers/tmp";
  port = 8096;
in
{
  misguided.jellyfin = {
    includes = [ misguided.oci ];

    settings = {
      publishedServerUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Public URL Jellyfin advertises to clients (optional).";
      };
      sopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "SOPS file with a `jellyfin-url` key (used when publishedServerUrl is null).";
      };
    };

    nixos =
      { host, config, ... }:
      let
        cfg = host.settings.misguided.jellyfin;
        useSops = cfg.sopsFile != null && cfg.publishedServerUrl == null;
      in
      lib.optionalAttrs useSops {
        sops.secrets.jellyfin-url = {
          inherit (cfg) sopsFile;
          format = "yaml";
        };
        sops.templates."jellyfin.env".content = ''
          JELLYFIN_PublishedServerUrl=${config.sops.placeholder.jellyfin-url}
        '';
      }
      // {
        networking.firewall = {
          allowedTCPPorts = [ port ];
          allowedUDPPorts = [ 7359 ]; # client auto-discovery
        };

        systemd.tmpfiles.rules = map (d: "d ${base}/${d} 0755 root root -") [
          "config"
          "cache"
          "media"
          "media2"
          "fonts"
        ];

        virtualisation.oci-containers.containers.jellyfin = {
          image = "docker.io/jellyfin/jellyfin:latest";
          environmentFiles = lib.optionals useSops [ config.sops.templates."jellyfin.env".path ];
          ports = [
            "${toString port}:8096/tcp"
            "7359:7359/udp"
          ];
          environment = {
            TMPDIR = tmpDir;
          }
          // lib.optionalAttrs (cfg.publishedServerUrl != null) {
            JELLYFIN_PublishedServerUrl = cfg.publishedServerUrl;
          };
          volumes = [
            "${base}/config:/config"
            "${base}/cache:/cache"
            "${base}/media:/media"
            "${base}/media2:/media2:ro"
            "${base}/fonts:/usr/local/share/fonts/custom:ro"
            "${tmpDir}:${tmpDir}"
          ];
        };
      };
  };
}
