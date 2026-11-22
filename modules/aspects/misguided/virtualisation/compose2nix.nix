# misguided.compose2nix — the compose2nix CLI: turn a docker-compose.yml into a
# NixOS module (that's how aspects/misguided/oci/immich.nix was made).
{ inputs, ... }:
{
  flake-file.inputs.compose2nix = {
    url = "github:aksiksi/compose2nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  misguided.compose2nix.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.compose2nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
