# misguided.immich — Immich photo library (generated with compose2nix, then
# cleaned up). Web UI: http://<host>:2283
#
# Photos go to /mnt/services/immich/library (the @services subvolume); the
# database lives in /var/lib/oci/immich/pg, which is persisted below.
#
# Secrets: without settings.misguided.immich.sopsFile the database password is
# Immich's sample "postgres" — fine on a LAN/Tailscale box, but put DB_PASSWORD
# and POSTGRES_PASSWORD in a sops file before exposing it anywhere.
# Needs misguided.podman + misguided.oci (the units below are podman-specific).
{ lib, misguided, ... }:
{
  misguided.immich = {
    includes = [
      misguided.podman
      misguided.oci
    ];

    settings.sopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "SOPS file (yaml) with an `immich` key holding env lines (DB_PASSWORD=…, POSTGRES_PASSWORD=…).";
    };

    persist.directories = [ "/var/lib/oci" ];

    nixos =
      {
        host,
        config,
        pkgs,
        ...
      }:
      let
        cfg = host.settings.misguided.immich // {
          dataDir = "/mnt/services";
          port = 2283;
        };

        uploadLocation = "${cfg.dataDir}/immich/library";
        dbDataLocation = "/var/lib/oci/immich/pg";
        immichVersion = "v2.7.5";
        dbUsername = "postgres";
        dbDatabaseName = "immich";

        env =
          {
            UPLOAD_LOCATION = uploadLocation;
            DB_DATA_LOCATION = dbDataLocation;
            TZ = config.time.timeZone;
            IMMICH_VERSION = immichVersion;
            DB_USERNAME = dbUsername;
            DB_DATABASE_NAME = dbDatabaseName;
          }
          // lib.optionalAttrs (cfg.sopsFile == null) {DB_PASSWORD = "postgres";};

        envFiles = lib.optionals (cfg.sopsFile != null) [config.sops.secrets.immich.path];
        afterSops = lib.optionals (cfg.sopsFile != null) ["sops-nix.service"];

        network = "podman-network-immich_default.service";
        root = "podman-compose-immich-root.target";
      in
      lib.optionalAttrs (cfg.sopsFile != null) {
        sops.secrets.immich = {
          inherit (cfg) sopsFile;
          format = "yaml";
        };
      }
      // {
        networking.firewall.allowedTCPPorts = [ cfg.port ];

        systemd.tmpfiles.rules = [
          "d ${uploadLocation} 0750 root root -"
          "d ${dbDataLocation} 0700 root root -"
        ];

        # Root target: starting it creates everything, stopping it tears it down.
        systemd.targets."podman-compose-immich-root" = {
          unitConfig.Description = "Immich (compose2nix root target)";
          wantedBy = ["multi-user.target"];
        };

        systemd.services = let
          member = extra: {
            serviceConfig.Restart = lib.mkOverride 90 "always";
            after = afterSops ++ [network] ++ (extra.after or []);
            requires = [network] ++ (extra.after or []);
            upheldBy = [network] ++ (extra.upheldBy or extra.after or []);
            partOf = [root];
            wantedBy = [root];
          };
        in {
          "podman-immich_machine_learning" = member {after = ["podman-volume-immich_model-cache.service"];};
          "podman-immich_postgres" = member {};
          "podman-immich_redis" = member {};
          "podman-immich_server" = member {upheldBy = ["podman-immich_postgres.service" "podman-immich_redis.service"];};

          "podman-network-immich_default" = {
            path = [pkgs.podman];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStop = "podman network rm -f immich_default";
            };
            script = "podman network inspect immich_default || podman network create immich_default";
            partOf = [root];
            wantedBy = [root];
          };

          "podman-volume-immich_model-cache" = {
            path = [pkgs.podman];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = "podman volume inspect immich_model-cache || podman volume create immich_model-cache";
            partOf = [root];
            wantedBy = [root];
          };
        };

        virtualisation.oci-containers.containers = let
          health = cmd: [
            "--health-cmd=${cmd}"
            "--health-interval=30s"
            "--health-timeout=5s"
            "--health-retries=3"
            "--health-start-period=5s"
            "--network=immich_default"
          ];
        in {
          immich_server = {
            image = "ghcr.io/immich-app/immich-server:${immichVersion}";
            environment = env;
            environmentFiles = envFiles;
            volumes = [
              "${uploadLocation}:/data:rw"
              "/etc/localtime:/etc/localtime:ro"
            ];
            ports = ["${toString cfg.port}:2283/tcp"];
            dependsOn = ["immich_redis" "immich_postgres"];
            log-driver = "journald";
            extraOptions = ["--network-alias=immich-server"] ++ health "none";
          };

          immich_machine_learning = {
            image = "ghcr.io/immich-app/immich-machine-learning:${immichVersion}";
            environment = env;
            environmentFiles = envFiles;
            volumes = ["immich_model-cache:/cache:rw"];
            log-driver = "journald";
            extraOptions = ["--network-alias=immich-machine-learning"] ++ health "none";
          };

          immich_redis = {
            image = "docker.io/valkey/valkey:9@sha256:3b55fbaa0cd93cf0d9d961f405e4dfcc70efe325e2d84da207a0a8e6d8fde4f9";
            log-driver = "journald";
            extraOptions = ["--network-alias=redis"] ++ health "redis-cli ping || exit 1";
          };

          immich_postgres = {
            image = "ghcr.io/immich-app/postgres:16-vectorchord0.3.0-pgvectors0.3.0";
            environment =
              env
              // {
                POSTGRES_USER = dbUsername;
                POSTGRES_DB = dbDatabaseName;
                POSTGRES_INITDB_ARGS = "--data-checksums";
              }
              // lib.optionalAttrs (cfg.sopsFile == null) {POSTGRES_PASSWORD = "postgres";};
            environmentFiles = envFiles;
            volumes = ["${dbDataLocation}:/var/lib/postgresql/data:rw"];
            log-driver = "journald";
            extraOptions = ["--shm-size=128mb" "--network-alias=database"] ++ health "none";
          };
        };
      };
  };
}
