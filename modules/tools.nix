# The framework's own tools, per system (was the packages/apps/devShells/
# formatter outputs of the old flake.nix):
#
#   mcli                 day-to-day helper (switch, update, deploy, push…)    everywhere
#   misguided-install    disko + nixos-install from the live ISO              Linux
#   misguided-recover    mount an installed system at /mnt for repair         Linux
#
#   nix run .#install -- Romina      nix run .#recover      nix run .   (= mcli)
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

      devShells = {
        default = pkgs.mkShell {
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
      }
      // lib.optionalAttrs isLinux {
        # COSMIC app / applet development (libcosmic, Rust). Use it from any project:
        #   nix develop ~/MisguidedFramework#cosmic
        # or let direnv load it on `cd`: put this in the project's .envrc, then `direnv allow`:
        #   use flake ~/MisguidedFramework#cosmic
        # Rust itself comes from rustup (misguided.langs.rust on Romina).
        # libcosmicAppHook brings pkg-config plus everything libcosmic links against
        # (Wayland, libxkbcommon, EGL/Vulkan, the X11 fallback) and sets the linker
        # flags, so `cargo run` / `just run` work on NixOS.
        cosmic = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            libcosmicAppHook
            just # COSMIC projects build with justfiles
            cargo-generate # new project: cargo generate gh:pop-os/cosmic-app-template
          ];
          buildInputs = [ pkgs.openssl ];
        };
      };

      formatter = pkgs.alejandra;
    };
}
