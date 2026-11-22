# misguided.cosmic — the COSMIC desktop (System76) with the COSMIC greeter as
# login screen. Wayland-only; XWayland stays on for Steam and older apps.
#
# COSMIC's own apps are listed in `exclude` below. Uncomment a line to remove
# that app; comment it back to restore it. The packages COSMIC needs to start
# at all (panel, launcher, files, settings, greeter…) are not listed: NixOS
# warns if you exclude one of those.
# (List mirrors nixpkgs' nixos/modules/services/desktop-managers/cosmic.nix.)
{
  misguided.cosmic = {
    # Not persisted: /var/lib/cosmic-greeter is the greeter user's home, which
    # NixOS recreates with the right owner on every boot. Persisting it gave it
    # root ownership and the login screen crashed (cosmic-comp: Permission denied).
    nixos =
      { pkgs, ... }:
      {
        services.desktopManager.cosmic.enable = true;
        services.displayManager.cosmic-greeter.enable = true;

        environment.cosmic.excludePackages = with pkgs; [
          # cosmic-edit              # Text Editor
          # cosmic-term              # Terminal
          # cosmic-player            # Media Player
          # cosmic-reader            # PDF reader
          # cosmic-viewer            # Image Viewer
          # cosmic-screenshot        # Screenshots
          # cosmic-monitor           # System Monitor
          # cosmic-wallpapers        # stock wallpapers
        ];

        environment.systemPackages = with pkgs; [
          cosmic-ext-tweaks # extra settings COSMIC Settings doesn't expose (themes, panel)
          gnome-disk-utility # Disks: partitions, SMART, and ISO -> USB (⋮ → Restore Disk Image)
        ];
      };
  };
}
