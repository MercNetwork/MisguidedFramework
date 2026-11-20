# Midra (formerly Malenia) — desktop. AMD Ryzen + Intel Arc. Keeps the gaming stack.
{pkgs, ...}: {
  imports = [
    ../common/desktop.nix
    ./hardware-configuration.nix
    ./disko.nix
    ./intel-arc.nix
  ];

  # Arc (Battlemage) runs on the `xe` driver, which wants a recent kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  misguided.gaming.enable = true;

  # RDP over Tailscale (setup: modules/nixos/remote-desktop.nix)
  misguided.desktop.remoteDesktop.enable = true;
}
