# nix-darwin side of Misguided Framework (Rellana).
# Base settings, the user + Home Manager wiring, and the `misguided.darwin.*` toggles.
{
  config,
  lib,
  pkgs,
  inputs,
  self,
  host,
  ...
}: let
  user = config.misguided.user.name;
in {
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ./defaults.nix
    ./homebrew.nix
    ./remote.nix
  ];

  options.misguided.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "mercury";
      description = "Short name of the macOS account (macOS creates it; it must already exist).";
    };

    home = lib.mkOption {
      type = lib.types.deferredModule;
      default = {};
      description = "Extra Home Manager config for the primary user on this Mac.";
    };
  };

  config = lib.mkMerge [
    {
      # nix-darwin's own state version (an integer, unrelated to "26.05").
      system.stateVersion = 6;
      system.primaryUser = user;

      networking = {
        hostName = lib.mkDefault host;
        localHostName = lib.mkDefault host;
        computerName = lib.mkDefault host;
      };

      nixpkgs.config.allowUnfree = true;
      programs.zsh.enable = true;

      environment.systemPackages = with pkgs; [
        self.packages.${pkgs.stdenv.hostPlatform.system}.mcli
        git
        nvd
      ];

      # Touch ID for sudo
      security.pam.services.sudo_local.touchIdAuth = true;

      users.users.${user} = {
        name = user;
        home = "/Users/${user}";
        shell = pkgs.zsh;
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        extraSpecialArgs = {inherit inputs self host;};
        users.${user} = {
          imports = [../../home.nix config.misguided.user.home];
          home.username = user;
          home.homeDirectory = "/Users/${user}";
        };
      };
    }

    # Only when nix-darwin manages Nix itself. With the Determinate installer,
    # set `nix.enable = false;` in hosts/Rellana and these are skipped.
    (lib.mkIf config.nix.enable {
      nix.settings = {
        experimental-features = ["nix-command" "flakes"];
        trusted-users = ["root" "@admin"];
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
}
