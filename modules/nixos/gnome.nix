# Full GNOME + GDM: shell, core apps and core developer tools (that's where
# GNOME Builder comes from). Games are off.
#
# No Wayland options on purpose: GNOME 50+ is Wayland-only and GDM follows it.
#
# EVERYTHING the NixOS GNOME module installs is listed in `exclude` below.
# Uncomment a line to remove that app; comment it back to restore it.
# (The list mirrors nixpkgs' nixos/modules/services/desktop-managers/gnome.nix.
#  If upstream renames or drops an app, evaluation will point at that line.)
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.misguided.desktop.gnome;
in {
  options.misguided.desktop.gnome = {
    enable = lib.mkEnableOption "GNOME desktop with GDM";

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        # ---- Excluded: help / onboarding / software store ------------------
        gnome-tour # first-login tour
        gnome-user-docs # help pages
        yelp # Help viewer
        gnome-software # Software (only installs alongside Flatpak anyway)

        # ---- Core shell ----------------------------------------------------
        # gnome-shell and mutter are mandatory and can't be excluded.
        # adwaita-icon-theme       # default icons
        # gnome-backgrounds        # stock wallpapers
        # gnome-bluetooth          # Bluetooth panel
        # gnome-color-manager      # colour profiles
        # gnome-control-center     # Settings (don't — you need it)
        # gnome-menus              # app menu spec
        # xdg-user-dirs            # ~/Documents, ~/Downloads… creation
        # xdg-user-dirs-gtk        # Files sidebar bookmarks
        # orca                     # screen reader

        # ---- Core apps -----------------------------------------------------
        # baobab                   # Disk Usage Analyzer
        # decibels                 # Audio Player
        # epiphany                 # Web (browser)
        # geary                    # Mail
        # gnome-calculator         # Calculator
        # gnome-calendar           # Calendar
        # gnome-characters         # Characters
        # gnome-clocks             # Clocks
        # gnome-connections        # Connections (RDP / VNC client)
        # gnome-console            # Console (terminal)
        # gnome-contacts           # Contacts
        # gnome-disk-utility       # Disks (also the ISO -> USB writer: Restore Disk Image)
        # gnome-font-viewer        # Fonts
        # gnome-logs               # Logs
        # gnome-maps               # Maps
        # gnome-music              # Music
        # gnome-system-monitor     # System Monitor
        # gnome-text-editor        # Text Editor
        # gnome-weather            # Weather
        # loupe                    # Image Viewer
        # nautilus                 # Files
        # papers                   # Document Viewer
        # seahorse                 # Passwords and Keys
        # showtime                 # Video Player
        # simple-scan              # Document Scanner
        # snapshot                 # Camera
        # sushi                    # quick previewer for Files (space bar)

        # ---- Core developer tools ------------------------------------------
        # gnome-builder            # Builder (you asked for this one — keep it)
        # d-spy                    # D-Bus inspector
        # dconf-editor             # dconf Editor
        # devhelp                  # API docs browser
        # sysprof                  # profiler
      ];
      description = "GNOME packages to leave out (environment.gnome.excludePackages).";
    };

    extraApps = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        refine # modern libadwaita "Tweaks": fonts, themes, titlebar buttons, experimental flags
        gnome-extension-manager # browse / install / configure extensions.gnome.org
        # gnome-tweaks            # the classic Tweaks app, if Refine is missing something
      ];
      description = "Extra GNOME apps installed with the desktop.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    services.gnome = {
      core-apps.enable = true;
      core-developer-tools.enable = true;
      games.enable = false;

      # Background services GNOME turns on by default — flip to false to drop them:
      # gnome-initial-setup.enable = false;     # first-login wizard
      # gnome-remote-desktop.enable = false;    # Settings > Sharing > Remote Desktop
      # gnome-user-share.enable = false;        # WebDAV file sharing
      # rygel.enable = false;                   # DLNA media sharing
      # gnome-browser-connector.enable = false; # extensions.gnome.org in the browser
      # gnome-online-accounts.enable = false;   # Online Accounts
      # localsearch.enable = false;             # file indexer (search in Files/overview)
      # tinysparql.enable = false;              # search database used by localsearch
      # gcr-ssh-agent.enable = false;           # GNOME's ssh-agent
    };

    environment.gnome.excludePackages = cfg.exclude;
    environment.systemPackages = cfg.extraApps;
  };
}
