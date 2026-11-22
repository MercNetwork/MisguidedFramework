# misguided.transmission — Transmission, headless: the torrent server behind
# Fragments. On Romina/Midra: Fragments → Preferences → Connect to Metyr, port 9091.
# Downloads land in /mnt/services/torrents/complete (group-writable for the user).
{ misguided, ... }:
let
  base = "/mnt/services/torrents"; # the @services subvolume (Metyr)
in
{
  misguided.transmission = {
    includes = [ misguided.transmission.user-group ];

    # settings.json, resume files, the torrent list. Downloads are on @services.
    persist.directories = [ "/var/lib/transmission" ];

    nixos =
      { pkgs, ... }:
      {
        services.transmission = {
          enable = true;
          package = pkgs.transmission_4;
          openPeerPorts = true;
          openRPCPort = true;
          downloadDirPermissions = "775";
          settings = {
            download-dir = "${base}/complete";
            incomplete-dir = "${base}/incomplete";
            incomplete-dir-enabled = true;
            rpc-bind-address = "0.0.0.0";
            rpc-port = 9091;
            rpc-whitelist-enabled = true;
            # localhost, the LAN and Tailscale (100.x)
            rpc-whitelist = "127.0.0.1,192.168.*.*,100.*.*.*";
            rpc-host-whitelist-enabled = false; # Fragments connects by hostname
            umask = 2; # files group-writable (002)
          };
        };
      };

    # Let the user move/delete finished downloads.
    user-group.nixos =
      { user, ... }:
      {
        users.users.${user.userName}.extraGroups = [ "transmission" ];
      };
  };
}
