# misguided.zed — Zed editor (`zeditor` on the command line).
#
# Language servers come from misguided.langs.* (and misguided.flutter for
# Dart), so they're on PATH and Zed uses them instead of downloading its own.
# The extension list is the `zedExtensions` quirk: every included aspect that
# wants an extension says so itself (langs.bash -> "basher", cli -> "sql"…),
# and this aspect collects them. On Linux the FHS build is used so anything Zed
# does download still runs on NixOS.
#
# settings.json is generated (read-only); put experiments in a project's
# .zed/settings.json or in userSettings below.
{
  den.quirks.zedExtensions.description = "Zed extensions an aspect wants installed";

  misguided.zed = {
    # Zed keeps its extensions, state and caches in the home directory.
    homeManager =
      {
        host,
        config,
        lib,
        pkgs,
        zedExtensions,
        ...
      }:
      let
        flake = "${config.home.homeDirectory}/MisguidedFramework";
        # [ "nixosConfigurations" "Romina" ] or [ "darwinConfigurations" "Rellana" ]
        hostAttr = lib.concatMapStringsSep "." (p: ''"${p}"'') host.intoAttr;
      in
      {
        programs.zed-editor = {
          enable = true;
          package = if pkgs.stdenv.hostPlatform.isLinux then pkgs.zed-editor-fhs else pkgs.zed-editor;

          extensions = lib.unique (
            [
              "nix"
              "toml"
              "make"
              "git-firefly"
            ]
            ++ lib.flatten zedExtensions
          );

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

            languages.Nix = {
              language_servers = [
                "nixd"
                "!nil"
              ];
              formatter.external.command = "alejandra";
            };

            lsp = {
              # Completion for nixpkgs and for this machine's options, read from the repo.
              nixd.settings = {
                formatting.command = [ "alejandra" ];
                nixpkgs.expr = "import (builtins.getFlake \"${flake}\").inputs.nixpkgs { }";
                options.${host.class}.expr = "(builtins.getFlake \"${flake}\").${hostAttr}.options";
              };
              rust-analyzer.binary.path_lookup = true;
            };
          };
        };

        programs.git.settings.core.editor = "zeditor --wait";
        home.sessionVariables.EDITOR = "zeditor --wait";
      };
  };
}
