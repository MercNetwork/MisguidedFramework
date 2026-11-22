# misguided.podman — Podman. Provides the `docker` command and socket unless
# misguided.docker is also on the host.
{ misguided, ... }:
{
  misguided.podman = {
    # Images, containers and named volumes (Immich's model cache…).
    persist.directories = [ "/var/lib/containers" ];

    nixos =
      { host, ... }:
      let
        dockerToo = host.hasAspect misguided.docker;
      in
      {
        virtualisation.podman = {
          enable = true;
          dockerCompat = !dockerToo;
          dockerSocket.enable = !dockerToo;
          defaultNetwork.settings.dns_enabled = true;
        };

        virtualisation.containers.containersConf.settings.engine = {
          color = "always";
          log_level = "info";
        };
      };
  };
}
