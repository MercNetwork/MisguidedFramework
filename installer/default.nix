# Misguided Framework tools: mcli (daily helper), misguided-install (Disko + nixos-install from
# the live ISO) and misguided-recover (mount an installed system for repair).
{
  pkgs,
  inputs,
}: let
  system = pkgs.stdenv.hostPlatform.system;
in
  {
    mcli = pkgs.writeShellApplication {
      name = "mcli";
      runtimeInputs = with pkgs; [nvd alejandra coreutils findutils git];
      text = builtins.readFile ./mcli.sh;
    };
  }
  // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    misguided-install = pkgs.writeShellApplication {
      name = "misguided-install";
      runtimeInputs = [
        inputs.disko.packages.${system}.disko
        pkgs.git
        pkgs.ssh-to-age
        pkgs.openssh
        pkgs.nixos-install-tools
        pkgs.coreutils
        pkgs.util-linux
      ];
      text = builtins.readFile ./install.sh;
    };

    misguided-recover = pkgs.writeShellApplication {
      name = "misguided-recover";
      runtimeInputs = with pkgs; [btrfs-progs cryptsetup coreutils util-linux findutils];
      text = builtins.readFile ./recover.sh;
    };
  }
