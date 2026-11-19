# Gaming stack (Midra only — Romina is a dev machine).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.misguided.gaming;
in {
  options.misguided.gaming.enable = lib.mkEnableOption "Steam, ProtonPlus and GameMode";

  config = lib.mkIf cfg.enable {
    programs.steam.enable = true;
    programs.gamemode.enable = true;
    environment.systemPackages = [pkgs.protonplus];
  };
}
