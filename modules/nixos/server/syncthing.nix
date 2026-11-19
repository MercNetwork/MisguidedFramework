# Syncthing, running as the primary user. Web UI on http://127.0.0.1:8384
# (reach it over SSH/Tailscale: `ssh -L 8384:localhost:8384 mercury@Metyr`).
{
  config,
  lib,
  ...
}: let
  cfg = config.misguided.services.syncthing;
  user = config.misguided.user.name;
in {
  options.misguided.services.syncthing.enable = lib.mkEnableOption "Syncthing as the primary user";

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      inherit user;
      group = "users";
      dataDir = "/home/${user}";
      configDir = "/home/${user}/.config/syncthing";
      openDefaultPorts = true;
    };
  };
}
