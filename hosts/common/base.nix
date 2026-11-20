# Everything every Misguided Framework NixOS machine gets. desktop.nix / server.nix add
# their role on top; host files override with plain assignments or lib.mkForce.
{
  config,
  lib,
  pkgs,
  inputs,
  self,
  host,
  ...
}: let
  user = config.misguided.user.name;
in {
  imports = [
    ./user.nix
    ../../modules/nixos
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = lib.mkDefault host;

  # --- Boot (Malenia overrides this with the Pi bootloader) ---
  boot.loader = {
    systemd-boot.enable = lib.mkDefault true;
    systemd-boot.configurationLimit = lib.mkDefault 10;
    efi.canTouchEfiVariables = lib.mkDefault true;
    timeout = lib.mkDefault 2;
  };

  # --- Network / locale / time ---
  networking.networkmanager.enable = lib.mkDefault true;

  # Every machine joins the tailnet (phone access, remote desktop, mcli push).
  misguided.services.tailscale.enable = true;
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
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["root" "@wheel"];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
    randomizedDelaySec = "45min";
  };
  nix.optimise.automatic = true;

  environment.systemPackages = with pkgs; [
    self.packages.${pkgs.stdenv.hostPlatform.system}.mcli
    git
    nvd # diff generations (used by mcli)
    nix-tree # audit closure size
    unzip
  ];

  # --- Home Manager: home.nix for everyone, plus the host's misguided.user.home ---
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {inherit inputs self host;};
    users.${user} = {
      imports = [../../home.nix config.misguided.user.home];
      home.username = user;
      home.homeDirectory = "/home/${user}";
    };
  };

  # Compatibility pin for fresh (disko) installs. Leave it alone afterwards.
  system.stateVersion = "26.05";
}
