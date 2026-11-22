# misguided.server — headless machines (Metyr, Malenia): SSH with keys only,
# nftables firewall and sops-nix for secrets. No desktop, no GUI apps.
# (was hosts/common/server.nix; Tailscale comes with misguided.base)
#
# mercury's SSH keys are in aspects/mercury.nix — add one BEFORE the first deploy.
{ misguided, ... }:
{
  misguided.server = {
    includes = [
      misguided.base
      misguided.ssh
      misguided.sops
    ];

    nixos =
      { lib, ... }:
      {
        networking.nftables.enable = true;
        networking.firewall.enable = true;

        # No local manual on headless boxes (smaller closure, faster Pi builds).
        documentation.nixos.enable = lib.mkDefault false;
      };
  };
}
