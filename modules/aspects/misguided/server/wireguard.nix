# misguided.wireguard — WireGuard tooling. Tunnels themselves go in the host
# (networking.wireguard or wg-quick); wg* interfaces are trusted by the firewall.
# Keep private keys in sops, not in a plain file on the (wiped) root.
{
  misguided.wireguard.nixos =
    { pkgs, ... }:
    {
      boot.kernelModules = [ "wireguard" ];
      environment.systemPackages = [ pkgs.wireguard-tools ];
      networking.firewall.trustedInterfaces = [ "wg+" ];
    };
}
