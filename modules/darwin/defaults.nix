# Sensible macOS defaults. Every value can be overridden in the host.
{
  config,
  lib,
  ...
}: let
  cfg = config.misguided.darwin.defaults;
in {
  options.misguided.darwin.defaults.enable =
    lib.mkEnableOption "Misguided Framework's macOS preferences (dark mode, fast key repeat, tidy Dock/Finder)";

  config = lib.mkIf cfg.enable {
    system.defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = lib.mkDefault "Dark";
        AppleShowAllExtensions = lib.mkDefault true;
        InitialKeyRepeat = lib.mkDefault 15;
        KeyRepeat = lib.mkDefault 2;
      };
      dock = {
        autohide = lib.mkDefault true;
        show-recents = lib.mkDefault false;
        mru-spaces = lib.mkDefault false;
      };
      finder = {
        AppleShowAllExtensions = lib.mkDefault true;
        FXPreferredViewStyle = lib.mkDefault "Nlsv"; # list view
        ShowPathbar = lib.mkDefault true;
      };
      trackpad.Clicking = lib.mkDefault true; # tap to click
    };
  };
}
