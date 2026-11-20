# Rellana (formerly Mohg) — Mac, Apple Silicon, nix-darwin.
#
# First build (after installing Nix and cloning the repo to ~/MisguidedFramework):
#   sudo nix run nix-darwin -- switch --flake ~/MisguidedFramework#Rellana
# Afterwards:
#   mcli switch
{...}: {
  imports = [../../modules/darwin];

  misguided = {
    darwin = {
      defaults.enable = true;
      tailscale.enable = true;
      screenSharing.enable = true; # VNC over Tailscale: rellana:5900
      homebrew = {
        enable = false; # needs Homebrew installed first (https://brew.sh)
        casks = [
          # "discord"
          # "zed"
        ];
        brews = [];
      };
    };

    # Same shell, CLI tools, git and languages as everywhere else (home.nix).
    # Add Mac-only Home Manager bits here, e.g. { misguided.zed.enable = true; }
    user.home = {};
  };
}
