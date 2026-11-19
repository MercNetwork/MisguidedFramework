# Podman. Provides the `docker` command and socket unless Docker is also on.
{
  config,
  lib,
  ...
}: let
  cfg = config.misguided.virtualisation.podman;
  dockerEnabled = config.misguided.virtualisation.docker.enable;
in {
  options.misguided.virtualisation.podman.enable = lib.mkEnableOption "Podman";

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      dockerCompat = !dockerEnabled;
      dockerSocket.enable = !dockerEnabled;
      defaultNetwork.settings.dns_enabled = true;
    };

    virtualisation.containers.containersConf.settings.engine = {
      color = "always";
      log_level = "info";
    };
  };
}
