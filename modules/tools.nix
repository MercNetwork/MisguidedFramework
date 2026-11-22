# The framework's own tools, per system (was the packages/apps/devShells/
# formatter outputs of the old flake.nix):
#
#   mcli                 day-to-day helper (switch, update, deploy, push…)    everywhere
#   misguided-install    disko + nixos-install from the live ISO              Linux
#   misguided-recover    mount an installed system at /mnt for repair         Linux
#
#   nix run .#install -- Romina      nix run .#recover      nix run .   (= mcli)
#
# nh.nix adds one more package per host: `nix run .#Romina -- switch`.
{ inputs, lib, ... }:
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
  ];

  perSystem =
    { pkgs, system, ... }:
    let
      t = import ../installer { inherit pkgs inputs; };
      isLinux = pkgs.stdenv.hostPlatform.isLinux;
      mkApp = drv: name: {
        type = "app";
        program = "${drv}/bin/${name}";
      };
    in
    {
      packages = {
        inherit (t) mcli;
        default = t.mcli;
      }
      // lib.optionalAttrs isLinux { inherit (t) misguided-install misguided-recover; };

      apps = {
        default = mkApp t.mcli "mcli";
        mcli = mkApp t.mcli "mcli";
      }
      // lib.optionalAttrs isLinux {
        install = mkApp t.misguided-install "misguided-install";
        recover = mkApp t.misguided-recover "misguided-recover";
      };

      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          alejandra
          nixd
          nvd
          nh
          sops
          age
          ssh-to-age
          git
        ];
      };

      formatter = pkgs.alejandra;
    };
}
