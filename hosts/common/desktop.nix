# The shared graphical desktop (Romina, Midra): GNOME + GDM, audio, printing,
# fonts and the everyday GUI apps. GNOME's own app list lives in
# modules/nixos/gnome.nix — that's where you exclude what you don't use.
{
  pkgs,
  inputs,
  ...
}: {
  imports = [./base.nix];

  misguided.desktop.gnome.enable = true;

  # Audio / Printing
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
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
      serif = ["Noto Serif" "Liberation Serif"];
      sansSerif = ["Noto Sans" "Liberation Sans"];
      monospace = ["JetBrains Mono" "DejaVu Sans Mono"];
      emoji = ["Noto Color Emoji"];
    };
  };

  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    unrar
    discord
    fragments # torrents — Preferences → connect to Metyr's Transmission (port 9091)
    inputs.sidra.packages.${pkgs.stdenv.hostPlatform.system}.default # Apple Music
    # ISO -> USB: GNOME Disks → ⋮ → Restore Disk Image (or right-click the .iso in Files)
  ];

  # Desktop-only Home Manager bits (wallpapers)
  misguided.user.home.misguided.desktop.enable = true;
}
