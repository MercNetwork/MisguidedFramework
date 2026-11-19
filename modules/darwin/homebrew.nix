# Homebrew, managed declaratively. Install Homebrew itself once by hand
# (https://brew.sh). With cleanup = "zap", anything not listed is removed on switch.
{
  config,
  lib,
  ...
}: let
  cfg = config.misguided.darwin.homebrew;
in {
  options.misguided.darwin.homebrew = {
    enable = lib.mkEnableOption "declarative Homebrew";

    casks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["firefox" "raycast"];
      description = "GUI apps (Homebrew casks).";
    };

    brews = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "CLI formulae.";
    };

    cleanup = lib.mkOption {
      type = lib.types.enum ["none" "uninstall" "zap"];
      default = "none";
      description = "What to do with Homebrew packages not listed here.";
    };
  };

  config = lib.mkIf cfg.enable {
    homebrew = {
      enable = true;
      inherit (cfg) casks brews;
      onActivation = {
        autoUpdate = false;
        upgrade = false;
        inherit (cfg) cleanup;
      };
    };
  };
}
