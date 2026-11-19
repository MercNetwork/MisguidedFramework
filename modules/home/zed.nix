# Zed editor (`zeditor` on the command line).
#
# Language servers come from modules/home/langs.nix (and flutter.nix for Dart),
# so they're on PATH and Zed uses them instead of downloading its own. The
# extension list follows whichever languages are enabled. On Linux the FHS
# build is used so anything Zed does download still runs on NixOS.
#
# settings.json is generated (read-only); put experiments in a project's
# .zed/settings.json or move them into userSettings below.
{
  config,
  lib,
  pkgs,
  host,
  ...
}: let
  cfg = config.misguided.zed;
  flake = "${config.home.homeDirectory}/MisguidedFramework";
  langs = config.misguided.langs;
  lang = name: langs.${name}.enable;

  extensions =
    ["nix" "toml" "make" "git-firefly"]
    ++ lib.optionals (lang "bash") ["basher"]
    ++ lib.optionals (lang "docker") ["dockerfile" "docker-compose"]
    ++ lib.optionals (lang "java") ["java"]
    ++ lib.optionals (lang "latex") ["latex"]
    ++ lib.optionals (lang "lua") ["lua"]
    ++ lib.optionals (lang "nginx") ["nginx"]
    ++ lib.optionals (lang "qml") ["qml"]
    ++ lib.optionals (lang "typst") ["typst"]
    ++ lib.optionals (lang "web") ["html" "svelte" "vue"]
    ++ lib.optionals config.misguided.cli.sqlite.enable ["sql"]
    ++ lib.optionals config.misguided.flutter.enable ["dart"]
    ++ cfg.extraExtensions;
in {
  options.misguided.zed = {
    enable = lib.mkEnableOption "the Zed editor";

    extraExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["catppuccin"];
      description = "More extensions (names from zed.dev/extensions).";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      package =
        if pkgs.stdenv.hostPlatform.isLinux
        then pkgs.zed-editor-fhs
        else pkgs.zed-editor;

      extensions = lib.unique extensions;

      userSettings = {
        auto_update = false; # Nix updates Zed
        telemetry = {
          diagnostics = false;
          metrics = false;
        };

        theme = {
          mode = "system";
          light = "One Light";
          dark = "One Dark";
        };
        buffer_font_family = "JetBrains Mono";
        buffer_font_size = 15;
        ui_font_size = 16;

        load_direnv = "shell_hook";
        format_on_save = "on";

        languages = {
          Nix = {
            language_servers = ["nixd" "!nil"];
            formatter.external.command = "alejandra";
          };
        };

        lsp = {
          # Completion for nixpkgs and for this machine's NixOS options, read from the repo.
          nixd.settings = {
            formatting.command = ["alejandra"];
            nixpkgs.expr = "import (builtins.getFlake \"${flake}\").inputs.nixpkgs { }";
            options.nixos.expr = "(builtins.getFlake \"${flake}\").nixosConfigurations.${host}.options";
          };
          rust-analyzer.binary.path_lookup = true;
        };
      };
    };

    home.sessionVariables.EDITOR = "zeditor --wait";
  };
}
