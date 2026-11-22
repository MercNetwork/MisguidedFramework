# misguided.pgadmin — pgAdmin 4 web UI for PostgreSQL. Web UI: http://<host>:9999
# Login comes from the sops file (PGADMIN_DEFAULT_EMAIL / PGADMIN_DEFAULT_PASSWORD).
{ lib, misguided, ... }:
let
  dataPath = "/var/lib/pgadmin"; # owned by UID/GID 5050
  tmpDir = "/var/lib/containers/tmp";
  port = 9999;
in
{
  misguided.pgadmin = {
    includes = [ misguided.oci ];

    settings.sopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "SOPS file (yaml) with a `pgadmin` key holding env lines.";
    };

    # Ownership (5050:5050) is fixed by the tmpfiles rule below.
    persist.directories = [ dataPath ];

    nixos =
      { host, config, ... }:
      let
        cfg = host.settings.misguided.pgadmin;
      in
      lib.optionalAttrs (cfg.sopsFile != null) {
        sops.secrets.pgadmin = {
          inherit (cfg) sopsFile;
          format = "yaml";
        };
      }
      // {
        networking.firewall.allowedTCPPorts = [ port ];

        systemd.tmpfiles.rules = [ "d ${dataPath} 0700 5050 5050 -" ];

        virtualisation.oci-containers.containers.pgadmin = {
          image = "docker.io/dpage/pgadmin4:latest";
          ports = [ "${toString port}:80" ];
          volumes = [ "${dataPath}:/var/lib/pgadmin" ];
          environmentFiles = lib.optionals (cfg.sopsFile != null) [ config.sops.secrets.pgadmin.path ];
          environment.TMPDIR = tmpDir;
          extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
        };
      };
  };
}
