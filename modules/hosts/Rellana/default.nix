# Rellana (formerly Mohg) — Mac, Apple Silicon, nix-darwin. No disko and no
# impermanence here: macOS owns the disk.
#
# First build (after installing Nix and cloning the repo to ~/MisguidedFramework):
#   sudo nix run nix-darwin -- switch --flake ~/MisguidedFramework#Rellana
# Afterwards:
#   mcli switch
#
# Same shell, CLI tools, git and languages as everywhere else (mercury.nix).
# Mac-only Home Manager bits: add a `homeManager` block below, or include
# misguided.zed etc. like Romina does.
{ misguided, ... }:
{
  den.aspects.Rellana = {
    includes = [
      misguided.darwin
      misguided.darwin.defaults
      misguided.darwin.tailscale
      misguided.darwin.screen-sharing # VNC over Tailscale: rellana:5900
      # misguided.darwin.homebrew      # needs Homebrew installed first (https://brew.sh)
    ];

    # darwin.homebrew.casks = [ "discord" "zed" ];
    # darwin.homebrew.brews = [ ];
  };
}
