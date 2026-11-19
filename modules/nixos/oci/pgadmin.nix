# pgAdmin 4 web UI for PostgreSQL. Web UI: http://<host>:9999
# Login comes from the sops file (PGADMIN_DEFAULT_EMAIL / PGADMIN_DEFAULT_PASSWORD).
{
  config,
  lib,
  ...
}: let
  cfg = config.misguided.oci.pgadmin;
  tmpDir = "/var/lib/containers/tmp";
in {
  options.misguided.oci.pgadmin = {
    enable = lib.mkEnableOption "pgAdmin 4";

    dataPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/pgadmin";
      description = "Host directory for pgAdmin data (owned by UID/GID 5050).";
    };

    sopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "SOPS file (yaml) with a `pgadmin` key holding env lines.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9999;
      description = "Host HTTP port for pgAdmin.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the pgAdmin port in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];

    sops.secrets.pgadmin = lib.mkIf (cfg.sopsFile != null) {
      inherit (cfg) sopsFile;
      format = "yaml";
    };

    systemd.tmpfiles.rules = ["d ${cfg.dataPath} 0700 5050 5050 -"];

    virtualisation.oci-containers.containers.pgadmin = {
      image = "docker.io/dpage/pgadmin4:latest";
      ports = ["${toString cfg.port}:80"];
      volumes = ["${cfg.dataPath}:/var/lib/pgadmin"];
      environmentFiles = lib.optionals (cfg.sopsFile != null) [config.sops.secrets.pgadmin.path];
      environment.TMPDIR = tmpDir;
      extraOptions = ["--add-host=host.docker.internal:host-gateway"];
    };
  };
}
