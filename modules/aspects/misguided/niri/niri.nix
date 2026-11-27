# misguided.niri — niri, the scrollable-tiling compositor, as a second session
# next to COSMIC. Opt-in: add `misguided.niri` to a host that has
# misguided.desktop, rebuild, then pick "Niri" or "COSMIC" on the login screen.
# COSMIC stays the default session.
#
# Adapted from https://gitlab.com/trungdaohieutrung/endeavouros-niri (GPL-3.0),
# with that setup's apps swapped for the COSMIC ones this framework already has:
#
#   ghostty               -> COSMIC Terminal       thunar  -> COSMIC Files
#   xed                   -> COSMIC Text Editor    btop    -> COSMIC System Monitor
#   hyprlock / swaylock   -> COSMIC lock screen    swayidle -> cosmic-idle
#   dunst                 -> cosmic-notifications  waypaper + swaybg -> cosmic-bg
#   polkit-kde agent      -> cosmic-osd
#   pavucontrol, azote, wiremix, bluetoothctl -> COSMIC Settings pages
#
# Kept from the original: waybar, fuzzel (launcher and the Mod+X / Mod+A / Mod+V
# menus) and cliphist. Not brought over: the shell, prompt, GTK/Qt theme and app
# configs (zsh, starship, cava, spicetify…): misguided.shell and COSMIC already
# cover those. Since the COSMIC pieces read COSMIC's settings, the wallpaper,
# theme, screen-off/suspend times and notification settings you choose in COSMIC
# Settings apply in niri too, from either session.
#
# The configs sit next to this file and are linked into ~/.config by Home
# Manager, so they're read-only there: edit them here and rebuild.
#   config.kdl, conf/*.kdl   niri (keybinds in conf/binds.kdl; Mod+Shift+/ lists them)
#   waybar/                  the bar
#   fuzzel.ini               the launcher
#   power-menu.sh            Mod+X / waybar power button
{
  misguided.niri = {
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cosmic-greeter = config.services.displayManager.cosmic-greeter.package;

        # COSMIC's lock screen is cosmic-greeter run as the user. It asks logind
        # for the session of its *parent* process and waits for that session's
        # Lock signal (cosmic-greeter src/logind.rs). niri runs as a systemd user
        # service and moves everything it spawns into a user scope outside the
        # login session, so it can't be started from niri's autostart. This
        # script is what the login screen runs instead of plain `niri-session`:
        # it's inside the login session, so it starts the locker as its own child
        # once niri is up, then runs niri-session as usual.
        session = pkgs.writeShellScript "niri-cosmic-session" ''
          systemctl=${lib.getExe' config.systemd.package "systemctl"}
          (
            for _ in {1..300}; do # wait up to 30 s for niri.service
              if "$systemctl" --user -q is-active niri.service; then
                WAYLAND_DISPLAY=$("$systemctl" --user show-environment | ${lib.getExe' pkgs.gnused "sed"} -n 's/^WAYLAND_DISPLAY=//p')
                export WAYLAND_DISPLAY
                exec ${lib.getExe' cosmic-greeter "cosmic-greeter"}
              fi
              ${lib.getExe' pkgs.coreutils "sleep"} 0.1
            done
          ) &
          locker=$!

          ${lib.getExe' pkgs.niri "niri-session"} "$@"
          status=$?
          kill "$locker" 2>/dev/null
          exit "$status"
        '';

        # nixpkgs' niri with its login-screen entry pointed at the script above.
        # Only the .desktop file changes, so nothing is rebuilt.
        niri = pkgs.symlinkJoin {
          name = "niri-${pkgs.niri.version}";
          paths = [ pkgs.niri ];
          postBuild = ''
            rm $out/share/wayland-sessions/niri.desktop
            substitute ${pkgs.niri}/share/wayland-sessions/niri.desktop \
              $out/share/wayland-sessions/niri.desktop \
              --replace-fail "Exec=niri-session" "Exec=${session}"
          '';
          inherit (pkgs.niri) meta passthru version;
        };

        power-menu = pkgs.writeShellScriptBin "niri-power-menu" (builtins.readFile ./power-menu.sh);
      in
      {
        programs.niri = {
          enable = true;
          package = niri;
          # File pickers use the GTK dialog instead of pulling in Nautilus.
          # (COSMIC Files is still the file manager: Mod+E.)
          useNautilus = false;
        };

        # The niri module makes itself the default session; keep COSMIC.
        services.displayManager.defaultSession = lib.mkOverride 999 "cosmic";

        environment.systemPackages = with pkgs; [
          power-menu
          waybar
          fuzzel
          cliphist # clipboard history (Mod+V)
          wl-clipboard
          brightnessctl # brightness keys
          wireplumber # wpctl, for the volume keys
          xwayland-satellite # X11 apps (Steam…); niri starts it on demand

          # Bound to keys in niri. COSMIC installs them too, but they stay here
          # even if one gets excluded in cosmic.nix.
          cosmic-term
          cosmic-edit
          cosmic-monitor
        ];

        # NVIDIA (Romina): niri's recommended fix for high VRAM use with the
        # proprietary driver. https://github.com/YaLTeR/niri/wiki/Nvidia
        environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json" =
          lib.mkIf (lib.elem "nvidia" config.services.xserver.videoDrivers)
            {
              text = builtins.toJSON {
                rules = [
                  {
                    pattern = {
                      feature = "procname";
                      matches = "niri";
                    };
                    profile = "Limit Free Buffer Pool On Wayland Compositors";
                  }
                ];
                profiles = [
                  {
                    name = "Limit Free Buffer Pool On Wayland Compositors";
                    settings = [
                      {
                        key = "GLVidHeapReuseRatio";
                        value = 0;
                      }
                    ];
                  }
                ];
              };
            };
      };

    # Reaches mercury through den.batteries.host-aspects.
    homeManager =
      { pkgs, ... }:
      {
        xdg.configFile = {
          "niri/config.kdl".source = ./config.kdl;
          "niri/conf".source = ./conf;
          "waybar/config.jsonc".source = ./waybar/config.jsonc;
          "waybar/style.css".source = ./waybar/style.css;
          "waybar/nix-snowflake.svg".source =
            "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          "fuzzel/fuzzel.ini".source = ./fuzzel.ini;
        };
      };
  };
}
