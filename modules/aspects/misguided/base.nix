# misguided.base — everything every NixOS machine gets (was hosts/common/base.nix).
# misguided.desktop / misguided.server include it and add their role on top.
# Hosts override with plain assignments in their own `nixos` block, or lib.mkForce.
{ inputs, misguided, ... }:
{
  misguided.base = {
    includes = [
      # Every machine joins the tailnet (phone access, remote desktop, mcli push).
      misguided.tailscale
    ];

    persist.directories = [
      "/etc/NetworkManager/system-connections" # saved Wi-Fi / VPN profiles
      "/var/lib/NetworkManager"
    ];

    nixos =
      { lib, pkgs, ... }:
      {
        # --- Boot (Malenia overrides this with the Pi bootloader) ---
        boot.loader = {
          systemd-boot.enable = lib.mkDefault true;
          systemd-boot.configurationLimit = lib.mkDefault 10;
          efi.canTouchEfiVariables = lib.mkDefault true;
          timeout = lib.mkDefault 2;
        };

        # --- Network / locale / time ---
        networking.networkmanager.enable = lib.mkDefault true;
        time.timeZone = lib.mkDefault "America/Chicago";
        i18n.defaultLocale = "en_US.UTF-8";
        i18n.extraLocaleSettings = lib.genAttrs [
          "LC_ADDRESS"
          "LC_IDENTIFICATION"
          "LC_MEASUREMENT"
          "LC_MONETARY"
          "LC_NAME"
          "LC_NUMERIC"
          "LC_PAPER"
          "LC_TELEPHONE"
          "LC_TIME"
        ] (_: "en_US.UTF-8");

        # --- Nix itself ---
        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [
            "root"
            "@wheel"
          ];
        };
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
          randomizedDelaySec = "45min";
        };
        nix.optimise.automatic = true;

        environment.systemPackages = [
          inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.mcli
          pkgs.git
          pkgs.nvd # diff generations (used by mcli)
          pkgs.nix-tree # audit closure size
          pkgs.unzip
        ];
      };
  };
}
