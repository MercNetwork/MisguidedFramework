# Transmission, headless — the torrent server behind Fragments.
# On Romina/Midra: Fragments → Preferences → Connect to Metyr, port 9091.
# Downloads land in <dataDir>/torrents/complete (group-writable for mercury).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.misguided.services.transmission;
  base = "${cfg.dataDir}/torrents";
in {
  options.misguided.services.transmission = {
    enable = lib.mkEnableOption "Transmission torrent daemon (remote-controlled by Fragments)";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/services";
      description = "Root for service data; torrents go in <dataDir>/torrents.";
    };

    rpcWhitelist = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1,192.168.*.*,100.*.*.*";
      description = "Who may control the daemon: localhost, the LAN and Tailscale (100.x).";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the RPC port (9091) and the peer port.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.transmission = {
      enable = true;
      package = pkgs.transmission_4;
      openPeerPorts = cfg.openFirewall;
      openRPCPort = cfg.openFirewall;
      downloadDirPermissions = "775";
      settings = {
        download-dir = "${base}/complete";
        incomplete-dir = "${base}/incomplete";
        incomplete-dir-enabled = true;
        rpc-bind-address = "0.0.0.0";
        rpc-port = 9091;
        rpc-whitelist-enabled = true;
        rpc-whitelist = cfg.rpcWhitelist;
        rpc-host-whitelist-enabled = false; # Fragments connects by hostname
        umask = 2; # files group-writable (002)
      };
    };

    # Let mercury move/delete finished downloads.
    misguided.user.extraGroups = ["transmission"];
  };
}
