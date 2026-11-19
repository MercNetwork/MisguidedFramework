# AdGuard Home: network-wide DNS ad blocking. Point your router's DNS at the
# server. Only the subnets listed below may query it or open the web UI.
# Needs networking.nftables.enable (set in hosts/common/server.nix).
{
  config,
  lib,
  ...
}: let
  cfg = config.misguided.services.adguard;
in {
  options.misguided.services.adguard = {
    enable = lib.mkEnableOption "AdGuard Home";

    port = lib.mkOption {
      type = lib.types.port;
      default = 9998;
      description = "Web UI port for AdGuard Home.";
    };

    allowedSubnets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["192.168.0.0/16"];
      example = ["192.168.1.0/24"];
      description = "Subnets allowed to query DNS and open the web UI (Tailscale is trusted separately).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Free port 53 if systemd-resolved is running.
    services.resolved.settings.Resolve.DNSStubListener = "no";

    networking.firewall.extraInputRules = lib.mkAfter (lib.concatMapStringsSep "\n" (subnet: ''
        ip saddr ${subnet} tcp dport { 53, ${toString cfg.port} } accept
        ip saddr ${subnet} udp dport 53 accept
      '')
      cfg.allowedSubnets);

    services.adguardhome = {
      enable = true;
      openFirewall = false;
      host = "0.0.0.0";
      inherit (cfg) port;
      settings = {
        dns = {
          bootstrap_dns = ["9.9.9.9" "1.1.1.2"];
          upstream_dns = [
            "https://dns.quad9.net/dns-query"
            "https://dns.mullvad.net/dns-query"
            "https://security.cloudflare-dns.com/dns-query"
          ];
          upstream_mode = "fastest_addr";
        };
        filtering = {
          protection_enabled = true;
          filtering_enabled = true;
          parental_enabled = true;
          safe_search.enabled = true;
        };
        filters =
          map (url: {
            enabled = true;
            inherit url;
          }) [
            "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt"
            "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt"
          ];
      };
    };
  };
}
