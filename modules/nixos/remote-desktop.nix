# GNOME Remote Desktop in "Remote Login" mode: RDP straight to the GDM login
# screen, so you can reach the machine even when nobody is logged in. Each
# connection gets its own GNOME session as the user who signs in.
#
# Reachable over Tailscale only by default (tailscale0 is trusted; 3389 stays
# closed on the LAN). From the iPhone: Microsoft's "Windows App" → add PC →
# romina / midra (MagicDNS name or 100.x address).
#
# One-time setup on each machine, after the first switch (the RDP login is a
# separate credential, not your account password):
#   sudo grdctl --system rdp set-credentials <rdp-user> <rdp-password>
#   sudo grdctl --system rdp enable
#   sudo grdctl --system status        # check it's on
# The TLS certificate is generated automatically on first start.
{
  config,
  lib,
  ...
}: let
  cfg = config.misguided.desktop.remoteDesktop;
  noIdleSuspendOnAC = {
    settings."org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing";
  };
in {
  options.misguided.desktop.remoteDesktop = {
    enable = lib.mkEnableOption "GNOME Remote Desktop (RDP Remote Login)";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Also open RDP (3389) on the LAN. Off = Tailscale only.";
    };

    stayAwakeOnAC = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Don't idle-suspend while on AC power (at the login screen and in sessions),
        so the machine stays reachable. Battery, lid close and manual suspend still work.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.misguided.desktop.gnome.enable;
        message = "misguided.desktop.remoteDesktop needs misguided.desktop.gnome.enable.";
      }
    ];

    services.gnome.gnome-remote-desktop.enable = true;

    # The system (Remote Login) daemon isn't started by default on NixOS.
    systemd.services.gnome-remote-desktop.wantedBy = ["graphical.target"];

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [3389];

    programs.dconf.profiles = lib.mkIf cfg.stayAwakeOnAC {
      gdm.databases = [noIdleSuspendOnAC];
      user.databases = [noIdleSuspendOnAC];
    };
  };
}
