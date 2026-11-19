{
  description = "Misguided Framework — mercury's NixOS / nix-darwin homelab (Unstable)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Rellana (macOS)
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Declarative disk layouts (hosts/<Host>/disko.nix), used by misguided-install
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Secrets for the server stack (Metyr)
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Turns docker-compose files into NixOS modules (Metyr)
    compose2nix.url = "github:aksiksi/compose2nix";
    compose2nix.inputs.nixpkgs.follows = "nixpkgs";

    # Lightweight NixOS VMs (Malenia)
    microvm.url = "github:microvm-nix/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";

    # Raspberry Pi 5 kernel, firmware and bootloader (Malenia).
    # Deliberately NOT following our nixpkgs so the Pi kernel comes from their cache.
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
  };

  outputs = {
    self,
    nixpkgs,
    nix-darwin,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;

    linuxSystems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = lib.genAttrs (linuxSystems ++ ["aarch64-darwin"]);

    # One NixOS machine = hosts/<host>/default.nix (+ hosts/common via its imports)
    mkHost = {
      host,
      system ? "x86_64-linux",
      modules ? [],
      specialArgs ? {},
    }:
      lib.nixosSystem {
        specialArgs = {inherit inputs self host;} // specialArgs;
        modules =
          [
            {nixpkgs.hostPlatform = lib.mkDefault system;}
            ./hosts/${host}
          ]
          ++ modules;
      };

    tools = system: import ./installer {
      pkgs = nixpkgs.legacyPackages.${system};
      inherit inputs;
    };
  in {
    nixosConfigurations = {
      # Dev laptop — the source of the lab (Intel + NVIDIA)
      Romina = mkHost {host = "Romina";};

      # Desktop (AMD + Intel Arc), keeps the gaming stack
      Midra = mkHost {host = "Midra";};

      # Homelab / self-hosting server
      Metyr = mkHost {host = "Metyr";};

      # Raspberry Pi 5 (8 GB) — microvm host
      Malenia = mkHost {
        host = "Malenia";
        system = "aarch64-linux";
        specialArgs = {inherit (inputs) nixos-raspberrypi;};
        modules = with inputs.nixos-raspberrypi.nixosModules; [
          inputs.nixos-raspberrypi.lib.inject-overlays
          raspberry-pi-5.base
          raspberry-pi-5.bluetooth
          # raspberry-pi-5.page-size-16k  # see hosts/Malenia/default.nix before enabling
        ];
      };
    };

    darwinConfigurations = {
      # Mac (Apple Silicon)
      Rellana = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit inputs self;
          host = "Rellana";
        };
        modules = [
          {nixpkgs.hostPlatform = "aarch64-darwin";}
          ./hosts/Rellana
        ];
      };
    };

    # mcli everywhere; the installer and recovery tool on Linux only
    packages = forAllSystems (system: let
      t = tools system;
    in
      {
        inherit (t) mcli;
        default = t.mcli;
      }
      // lib.optionalAttrs (lib.elem system linuxSystems) {
        inherit (t) misguided-install misguided-recover;
      });

    apps = forAllSystems (system: let
      t = tools system;
      mkApp = drv: name: {
        type = "app";
        program = "${drv}/bin/${name}";
      };
    in
      {
        default = mkApp t.mcli "mcli";
        mcli = mkApp t.mcli "mcli";
      }
      // lib.optionalAttrs (lib.elem system linuxSystems) {
        install = mkApp t.misguided-install "misguided-install";
        recover = mkApp t.misguided-recover "misguided-recover";
      });

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [alejandra nixd nvd sops age ssh-to-age git];
      };
    });

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
