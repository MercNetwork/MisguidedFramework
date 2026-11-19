# WireGuard tooling. Tunnels themselves go in the host (networking.wireguard
# or wg-quick); wg* interfaces are trusted by the firewall.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.misguided.services.wireguard;
in {
  options.misguided.services.wireguard.enable = lib.mkEnableOption "WireGuard tools";

  config = lib.mkIf cfg.enable {
    boot.kernelModules = ["wireguard"];
    environment.systemPackages = [pkgs.wireguard-tools];
    networking.firewall.trustedInterfaces = ["wg+"];
  };
}
