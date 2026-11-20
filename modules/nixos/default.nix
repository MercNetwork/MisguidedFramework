# Every Misguided Framework NixOS module. Each one only declares `misguided.*` options and
# does nothing until a host (or hosts/common/*) switches it on.
{
  imports = [
    ./disko.nix
    ./gnome.nix
    ./gaming.nix
    ./remote-desktop.nix
    ./sops.nix
    ./tailscale.nix

    ./server/adguard.nix
    ./server/caddy.nix
    ./server/cloudflared.nix
    ./server/ssh.nix
    ./server/syncthing.nix
    ./server/transmission.nix
    ./server/wireguard.nix

    ./oci/immich.nix
    ./oci/jellyfin.nix
    ./oci/pgadmin.nix

    ./virtualisation/compose2nix.nix
    ./virtualisation/docker.nix
    ./virtualisation/microvm.nix
    ./virtualisation/oci.nix
    ./virtualisation/podman.nix
  ];
}
