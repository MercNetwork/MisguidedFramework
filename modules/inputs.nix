# Core inputs. Run `nix run .#write-flake` after changing ANY flake-file.inputs
# (here or next to an aspect) — flake.nix is generated from them.
#
# Inputs only one feature needs are declared next to that feature:
#   disko          aspects/misguided/disk.nix
#   impermanence   aspects/misguided/impermanence.nix
#   sops-nix       aspects/misguided/server/sops.nix
#   compose2nix    aspects/misguided/virtualisation/compose2nix.nix
#   microvm        aspects/misguided/virtualisation/microvm.nix
#   sidra          aspects/misguided/desktop.nix
#   nixos-raspberrypi  hosts/Malenia/default.nix
{
  flake-file.description = "Misguided Framework — mercury's NixOS / nix-darwin homelab (den)";

  flake-file.inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # den's darwin hosts are instantiated with inputs.darwin (was `nix-darwin`).
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
