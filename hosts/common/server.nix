# Headless machines (Metyr, Malenia): SSH with keys only, Tailscale, nftables
# firewall and sops-nix for secrets. No desktop, no GUI apps.
{lib, ...}: {
  imports = [./base.nix];

  misguided = {
    services = {
      ssh.enable = true;
      tailscale.enable = true;
    };
    security.sops.enable = true;

    # REQUIRED before the first deploy — SSH is key-only, so without a key you
    # can only log in on the console. Paste `cat ~/.ssh/id_ed25519.pub` from Romina.
    user.authorizedKeys = [
      # "ssh-ed25519 AAAA... mercury@Romina"
    ];
  };

  networking.nftables.enable = true;
  networking.firewall.enable = true;

  # No local manual on headless boxes (smaller closure, faster Pi builds).
  documentation.nixos.enable = lib.mkDefault false;
}
