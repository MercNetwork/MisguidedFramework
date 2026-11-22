# What EVERY host, user and home gets, NixOS or macOS. Keep it to static
# values and den batteries (den's docs warn against putting
# parametric functions in den.default).
{ den, ... }:
{
  den.default = {
    # Compatibility pins for fresh (disko) installs. Leave them alone afterwards.
    nixos.system.stateVersion = "26.05";
    darwin.system.stateVersion = 6; # nix-darwin's own counter, unrelated to "26.05"
    homeManager.home.stateVersion = "26.05";

    nixos.nixpkgs.config.allowUnfree = true;
    darwin.nixpkgs.config.allowUnfree = true;

    # Home Manager as a NixOS / nix-darwin module, sharing the system's pkgs.
    nixos.home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
    };
    darwin.home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
    };

    includes = [
      # networking.hostName = the den host name (Romina, Midra…), which is
      # also what mcli uses to pick the configuration.
      den.batteries.hostname

      # users.users.<user> + home.username / home.homeDirectory.
      den.batteries.define-user
    ];
  };
}
