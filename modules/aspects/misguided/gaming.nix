# misguided.gaming — Steam, ProtonPlus and GameMode (Midra only — Romina is a
# dev machine). Steam's games and Proton prefixes live in ~/.local/share/Steam,
# which is on @home, so nothing extra to persist.
{
  misguided.gaming.nixos =
    { pkgs, ... }:
    {
      programs.steam.enable = true;
      programs.gamemode.enable = true;
      environment.systemPackages = [ pkgs.protonplus ];
    };
}
