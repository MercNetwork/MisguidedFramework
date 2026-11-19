# Jellyfin media server in a container. Web UI: http://<host>:8096
# Drop media into <dataDir>/jellyfin/media (and media2, mounted read-only).
{
  config,
  lib,
  ...
}: let
  cfg = config.misguided.oci.jellyfin;
  base = "${cfg.dataDir}/jellyfin";
  tmpDir = "/var/lib/containers/tmp";
  useSops = cfg.sopsFile != null && cfg.publishedServerUrl == null;
in {
  options.misguided.oci.jellyfin = {
    enable = lib.mkEnableOption "Jellyfin";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/services";
      description = "Root for service data; Jellyfin uses <dataDir>/jellyfin/{config,cache,media,media2,fonts}.";
    };

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

    port = lib.mkOption {
      type = lib.types.port;
      default = 8096;
      description = "Host HTTP port for Jellyfin.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the Jellyfin ports in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.port];
      allowedUDPPorts = [7359]; # client auto-discovery
    };

    systemd.tmpfiles.rules =
      map (d: "d ${base}/${d} 0755 root root -") ["config" "cache" "media" "media2" "fonts"];

    sops.secrets.jellyfin-url = lib.mkIf useSops {
      inherit (cfg) sopsFile;
      format = "yaml";
    };

    sops.templates."jellyfin.env" = lib.mkIf useSops {
      content = ''
        JELLYFIN_PublishedServerUrl=${config.sops.placeholder.jellyfin-url}
      '';
    };

    virtualisation.oci-containers.containers.jellyfin = {
      image = "docker.io/jellyfin/jellyfin:latest";
      environmentFiles = lib.optionals useSops [config.sops.templates."jellyfin.env".path];
      ports = [
        "${toString cfg.port}:8096/tcp"
        "7359:7359/udp"
      ];
      environment =
        {TMPDIR = tmpDir;}
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
}
