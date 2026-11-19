# Desktop-only Home Manager bits (switched on by hosts/common/desktop.nix).
# Apps come from GNOME itself (modules/nixos/gnome.nix); this only links the
# wallpapers folder.
{
  config,
  lib,
  ...
}: let
  cfg = config.misguided.desktop;
in {
  options.misguided.desktop.enable = lib.mkEnableOption "desktop Home Manager settings";

  config = lib.mkIf cfg.enable {
    # Wallpapers/ in the repo -> ~/Pictures/Wallpapers (read-only, from the Nix store).
    # New images must be `git add`ed before a rebuild picks them up.
    home.file."Pictures/Wallpapers".source = ../../Wallpapers;
  };
}
