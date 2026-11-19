# The interactive shell: zsh (oh-my-zsh), starship, eza, bat,
# fzf (fd + bat preview), zoxide, tmux, fastfetch, pay-respects and direnv.
# Every tool is on by default with `misguided.shell.enable`; switch one off with
# e.g. `misguided.shell.tmux.enable = false;`.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.misguided.shell;
  tools = ["zsh" "starship" "eza" "bat" "fzf" "zoxide" "tmux" "fastfetch" "payRespects" "direnv"];
  on = name: cfg.enable && cfg.${name}.enable;
in {
  options.misguided.shell =
    {enable = lib.mkEnableOption "the Misguided Framework shell environment";}
    // lib.genAttrs tools (name: {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable ${name} (when misguided.shell.enable is on).";
      };
    });

  config = lib.mkMerge [
    (lib.mkIf (on "zsh") {
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
    })

    (lib.mkIf (on "starship") {
      programs.starship = {
        enable = true;
        presets = ["gruvbox-rainbow"];
        settings = {
          add_newline = false;
          hostname.ssh_only = false;
        };
      };
    })

    (lib.mkIf (on "eza") {
      programs.eza = {
        enable = true;
        icons = "auto";
        git = true;
        extraOptions = ["--group-directories-first" "--header"];
      };
    })

    (lib.mkIf (on "bat") {
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
    })

    (lib.mkIf (on "fzf") {
      home.packages = [pkgs.fd];
      programs.fzf = {
        enable = true;
        defaultCommand = "fd --type f --strip-cwd-prefix --hidden --exclude .git";
        fileWidgetCommand = "fd --type f --strip-cwd-prefix --hidden --exclude .git";
        changeDirWidgetCommand = "fd --type d --strip-cwd-prefix --hidden --exclude .git";
        fileWidgetOptions = ["--preview '${lib.getExe pkgs.bat} --color=always --line-range :500 {}'"];
        historyWidgetOptions = ["--sort" "--exact"];
      };
    })

    (lib.mkIf (on "zoxide") {
      programs.zoxide.enable = true;
      home.sessionVariables._ZO_FZF_OPTS = "--exact --no-sort";
    })

    (lib.mkIf (on "tmux") {
      programs.tmux = {
        enable = true;
        clock24 = true;
        keyMode = "vi";
      };
    })

    (lib.mkIf (on "payRespects") {
      programs.pay-respects.enable = true;
    })

    (lib.mkIf (on "direnv") {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    })

    (lib.mkIf (on "fastfetch") {
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
    })
  ];
}
