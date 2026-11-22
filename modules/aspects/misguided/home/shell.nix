# misguided.shell — the interactive shell: zsh (oh-my-zsh), starship, eza, bat,
# fzf (fd + bat preview), zoxide, tmux, fastfetch, pay-respects and direnv.
#
# `misguided.shell` includes every tool. To drop one on a host, exclude it in
# that host's aspect:   excludes = [ misguided.shell.tmux ];
# or include only the ones you want:   includes = [ misguided.shell.zsh misguided.shell.eza ];
# (zsh itself is the login shell via den.batteries.user-shell in mercury.nix.)
{ lib, misguided, ... }:
{
  misguided.shell = {
    includes = [
      misguided.shell.zsh
      misguided.shell.starship
      misguided.shell.eza
      misguided.shell.bat
      misguided.shell.fzf
      misguided.shell.zoxide
      misguided.shell.tmux
      misguided.shell.pay-respects
      misguided.shell.direnv
      misguided.shell.fastfetch
    ];

    zsh.homeManager =
      { config, pkgs, ... }:
      {
        programs.zsh = {
          enable = true;
          enableCompletion = true;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;
          history = {
            size = 10000;
            path = "${config.xdg.dataHome}/zsh/history";
          };
          oh-my-zsh = {
            enable = true;
            plugins = ["git"];
          };
          plugins = [
            {
              name = "you-should-use";
              src = "${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use";
            }
          ];
          shellAliases = {
            ll = "ls -l";
            update = "mcli switch";
            garbage = "mcli clean";
            gs = "git status";
            ga = "git add .";
            gc = "git commit -m";
            gp = "git push";
          };
          initContent = ''
            # Quiet direnv: hide the per-variable load log
            export DIRENV_LOG_FORMAT=""
          '';
        };
      };

    starship.homeManager = {
      programs.starship = {
        enable = true;
        presets = ["gruvbox-rainbow"];
        settings = {
          add_newline = false;
          hostname.ssh_only = false;
        };
      };
    };

    eza.homeManager = {
      programs.eza = {
        enable = true;
        icons = "auto";
        git = true;
        extraOptions = ["--group-directories-first" "--header"];
      };
    };

    bat.homeManager =
      { pkgs, ... }:
      {
        programs.bat = {
          enable = true;
          config = {
            theme = "TwoDark";
            style = "numbers,changes,header";
            italic-text = "always";
          };
          extraPackages = with pkgs.bat-extras; [batman batpipe batdiff batwatch];
        };
        home.shellAliases = {
          cat = "bat";
          man = "batman";
        };
      };

    fzf.homeManager =
      { options, pkgs, ... }:
      let
        widgets = {
          fileWidget = {
            command = "fd --type f --strip-cwd-prefix --hidden --exclude .git";
            options = [ "--preview '${lib.getExe pkgs.bat} --color=always --line-range :500 {}'" ];
          };
          changeDirWidget.command = "fd --type d --strip-cwd-prefix --hidden --exclude .git";
          historyWidget.options = [
            "--sort"
            "--exact"
          ];
        };
      in
      {
        home.packages = [ pkgs.fd ];
        programs.fzf = {
          enable = true;
          defaultCommand = "fd --type f --strip-cwd-prefix --hidden --exclude .git";
        }
        # Home Manager 26.11 renamed fileWidgetCommand -> fileWidget.command etc.
        # Malenia runs the 26.05 release, so use whichever names exist.
        // (
          if options.programs.fzf ? fileWidget then
            widgets
          else
            {
              fileWidgetCommand = widgets.fileWidget.command;
              fileWidgetOptions = widgets.fileWidget.options;
              changeDirWidgetCommand = widgets.changeDirWidget.command;
              historyWidgetOptions = widgets.historyWidget.options;
            }
        );
      };

    zoxide.homeManager = {
      programs.zoxide.enable = true;
      home.sessionVariables._ZO_FZF_OPTS = "--exact --no-sort";
    };

    tmux.homeManager = {
      programs.tmux = {
        enable = true;
        clock24 = true;
        keyMode = "vi";
      };
    };

    pay-respects.homeManager = {
      programs.pay-respects.enable = true;
    };

    direnv.homeManager = {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };

    fastfetch.homeManager = {
      programs.fastfetch = {
        enable = true;
        settings = {
          logo.padding = {
            top = 1;
            left = 2;
            right = 4;
          };
          display = {
            separator = "  ";
            key.width = 14;
            percent.type = 3;
            bar = {
              char = {
                elapsed = "■";
                total = "□";
              };
              width = 12;
            };
          };
          modules = [
            "break"
            {
              type = "title";
              format = "{##cdd6f4}{user-name}{##585b70}@{##89dceb}{host-name}";
            }
            {
              type = "custom";
              format = "{##585b70}──────────────────────────────────";
            }
            {
              type = "os";
              key = "{##89dceb}  distro";
            }
            {
              type = "kernel";
              key = "{##89dceb}󰌽  kernel";
            }
            {
              type = "de";
              key = "{##89dceb}  desktop";
            }
            {
              type = "terminal";
              key = "{##89dceb}󰞷  term";
            }
            {
              type = "shell";
              key = "{##89dceb}󰞧  shell";
            }
            {
              type = "packages";
              key = "{##89dceb}󰏓  packages";
            }
            {
              type = "uptime";
              key = "{##89dceb}󱑎  uptime";
            }
            "break"
            {
              type = "cpu";
              key = "{##94e2d5}  cpu";
            }
            {
              type = "memory";
              key = "{##94e2d5}󰘚  memory";
            }
            {
              type = "disk";
              key = "{##94e2d5}󰋊  storage";
            }
            {
              type = "battery";
              key = "{##94e2d5}󱐋  power";
            }
            "break"
            {
              type = "colors";
              paddingLeft = 0;
              symbol = "circle";
            }
            "break"
          ];
        };
      };
    };
  };
}
