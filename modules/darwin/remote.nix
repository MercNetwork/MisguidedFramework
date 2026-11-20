# Remote access for the Mac: Tailscale + macOS Screen Sharing (VNC).
#
# Tailscale: after the first switch run `sudo tailscale up` once.
# Screen Sharing: reachable over the tailnet at rellana:5900. From the
# iPhone use a VNC client (e.g. Screens or RealVNC Viewer) and sign in with
# your macOS account. Turned on by the activation script below; if macOS
# refuses (newer releases may want it done by hand once), enable it in
# System Settings → General → Sharing → Screen Sharing.
{
  config,
  lib,
  ...
}: let
  cfg = config.misguided.darwin;
in {
  options.misguided.darwin = {
    tailscale.enable = lib.mkEnableOption "Tailscale (tailscaled from nixpkgs)";
    screenSharing.enable = lib.mkEnableOption "macOS Screen Sharing (VNC, port 5900)";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.tailscale.enable {
      services.tailscale = {
        enable = true;
        overrideLocalDns = true; # MagicDNS names (romina, metyr…) resolve on the Mac
      };
    })

    (lib.mkIf cfg.screenSharing.enable {
      system.activationScripts.postActivation.text = ''
        echo "enabling Screen Sharing..." >&2
        launchctl enable system/com.apple.screensharing
        launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true
      '';
    })
  ];
}
