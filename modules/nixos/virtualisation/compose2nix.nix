# compose2nix CLI: turn a docker-compose.yml into a NixOS module
# (that's how modules/nixos/oci/immich.nix was made).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.misguided.virtualisation.compose2nix;
in {
  options.misguided.virtualisation.compose2nix.enable = lib.mkEnableOption "compose2nix";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      inputs.compose2nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
