# Rootful Docker with buildx. The primary user joins the docker group.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.misguided.virtualisation.docker;
in {
  options.misguided.virtualisation.docker.enable = lib.mkEnableOption "Docker";

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      extraPackages = [pkgs.docker-buildx];
      daemon.settings.ipv6 = false;
    };
    environment.systemPackages = [pkgs.docker-buildx];
    misguided.user.extraGroups = ["docker"];
  };
}
