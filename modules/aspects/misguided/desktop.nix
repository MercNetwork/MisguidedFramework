# misguided.desktop — the shared graphical desktop (Romina, Midra): COSMIC,
# audio, printing, fonts and the everyday GUI apps (was
# hosts/common/desktop.nix + modules/home/desktop.nix). COSMIC's own app list
# lives in cosmic.nix — that's where you exclude what you don't use.
{ inputs, misguided, ... }:
{
  # Sidra — Apple Music desktop client. Not in nixpkgs. Left on its own
  # nixpkgs: it builds on CastLabs Electron (Widevine DRM).
  flake-file.inputs.sidra.url = "github:wimpysworld/sidra";

  misguided.desktop = {
    includes = [
      misguided.base
      misguided.cosmic
    ];

    persist.directories = [
      "/var/lib/bluetooth" # paired devices
      "/var/lib/cups" # printers
      "/var/lib/AccountsService" # user picture and session choice
      "/var/lib/colord"
      "/var/lib/upower"
      "/var/lib/boltd" # authorised Thunderbolt devices
    ];

    nixos =
      { pkgs, ... }:
      {
        # Audio / Printing
        services.printing.enable = true;
        services.pulseaudio.enable = false;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          # JACK apps: run them through `pw-jack` (services.pipewire.jack.enable
          # is deprecated — it leaks LD_LIBRARY_PATH into everything).
        };

        # System font stack. NixOS ships almost no fonts by default, so GTK apps
        # fall back to ugly bitmap fonts without this. Latin, CJK, emoji, monospace.
        fonts = {
          enableDefaultPackages = true;
          packages = with pkgs; [
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-color-emoji
            liberation_ttf
            dejavu_fonts
            jetbrains-mono
            nerd-fonts.jetbrains-mono
            fira-code
            fira-code-symbols
            font-awesome
          ];
          fontconfig.defaultFonts = {
            serif = [
              "Noto Serif"
              "Liberation Serif"
            ];
            sansSerif = [
              "Noto Sans"
              "Liberation Sans"
            ];
            monospace = [
              "JetBrains Mono"
              "DejaVu Sans Mono"
            ];
            emoji = [ "Noto Color Emoji" ];
          };
        };

        programs.firefox.enable = true;

        environment.systemPackages = [
          pkgs.unrar
          pkgs.pipewire.jack # pw-jack
          pkgs.discord
          pkgs.fragments # torrents — Preferences → connect to Metyr's Transmission (port 9091)
          inputs.sidra.packages.${pkgs.stdenv.hostPlatform.system}.default # Apple Music
        ];
      };

    # Reaches mercury through den.batteries.host-aspects.
    # Wallpapers/ in the repo -> ~/Pictures/Wallpapers (read-only, from the Nix store).
    # New images must be `git add`ed before a rebuild picks them up.
    homeManager.home.file."Pictures/Wallpapers".source = ../../../Wallpapers;
  };
}
