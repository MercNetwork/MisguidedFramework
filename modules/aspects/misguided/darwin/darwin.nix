# misguided.darwin — the nix-darwin side (Rellana): base settings plus the
# macOS toggles as nested aspects (was modules/darwin/*):
#
#   misguided.darwin.defaults        dark mode, fast key repeat, tidy Dock/Finder
#   misguided.darwin.homebrew        declarative Homebrew (install Homebrew first: https://brew.sh)
#   misguided.darwin.tailscale       tailscaled from nixpkgs
#   misguided.darwin.screen-sharing  macOS Screen Sharing (VNC, port 5900) over Tailscale
#
# The account itself is created by macOS; den.batteries.define-user and
# primary-user (mercury.nix) only point nix-darwin and Home Manager at it.
{ inputs, ... }:
{
  misguided.darwin = {
    darwin =
      {
        config,
        host,
        lib,
        pkgs,
        ...
      }:
      lib.mkMerge [
        {
          networking = {
            localHostName = lib.mkDefault host.hostName;
            computerName = lib.mkDefault host.hostName;
          };

          programs.zsh.enable = true;

          environment.systemPackages = [
            inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.mcli
            pkgs.git
            pkgs.nvd
          ];

          # Touch ID for sudo
          security.pam.services.sudo_local.touchIdAuth = true;
        }

        # Only when nix-darwin manages Nix itself. With the Determinate installer,
        # set `darwin.nix.enable = false;` on Rellana and these are skipped.
        (lib.mkIf config.nix.enable {
          nix.settings = {
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            trusted-users = [
              "root"
              "@admin"
            ];
          };
          nix.gc = {
            automatic = true;
            interval = {
              Weekday = 0;
              Hour = 3;
              Minute = 0;
            };
            options = "--delete-older-than 7d";
          };
          nix.optimise.automatic = true;
        })
      ];

    defaults.darwin =
      { lib, ... }:
      {
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

    # Casks / brews go in the host: darwin.homebrew.casks = [ "discord" ];
    # With onActivation.cleanup = "zap", anything not listed is removed on switch.
    homebrew.darwin =
      { lib, ... }:
      {
        homebrew = {
          enable = true;
          onActivation = {
            autoUpdate = false;
            upgrade = false;
            cleanup = lib.mkDefault "none";
          };
        };
      };

    # After the first switch run `sudo tailscale up` once.
    tailscale.darwin.services.tailscale = {
      enable = true;
      overrideLocalDns = true; # MagicDNS names (romina, metyr…) resolve on the Mac
    };

    # Reachable over the tailnet at rellana:5900. From the iPhone use a VNC
    # client (Screens, RealVNC Viewer) and sign in with your macOS account. If
    # macOS refuses (newer releases may want it done by hand once), enable it in
    # System Settings → General → Sharing → Screen Sharing.
    screen-sharing.darwin.system.activationScripts.postActivation.text = ''
      echo "enabling Screen Sharing..." >&2
      launchctl enable system/com.apple.screensharing
      launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true
    '';
  };
}
