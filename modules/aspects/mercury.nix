# mercury — the one user, on every machine. Replaces hosts/common/user.nix
# (the account) and home.nix (the Home Manager config every machine gets).
#
# Hosts add to mercury's home by putting `homeManager` content on their own
# aspect (or on aspects they include): `den.batteries.host-aspects` below
# carries it over. That's what `misguided.user.home` used to do.
{ den, misguided, ... }:
let
  # Default password: "chloe". Replace with your own hash:
  #   mkpasswd -m sha-512        (or: openssl passwd -6)
  hashedPassword = "$6$mercurylab$Q8edhZ/zU3KqTP4SO4KbJc9fM8GM4kasPnjl/Qy85GH79cA.OxGo5a02K40ztFfZL47LB6UsSHYchKuO.mmio.";

  # SSH is key-only on the servers: these keys may log in as mercury AND as
  # root (mcli deploy / push). Public keys only (`cat ~/.ssh/id_ed25519.pub`);
  # add one line per device (e.g. the iPhone's SSH app).
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGxLsWGH6cI2jR/zErku/m7AMlOnP5rltMuo5Usr/DDf mercury@Romina"
  ];
in
{
  den.aspects.mercury = {
    includes = [
      den.batteries.primary-user # wheel + networkmanager; system.primaryUser on macOS
      (den.batteries.user-shell "zsh") # login shell at OS and Home Manager level
      den.batteries.host-aspects # host `homeManager` content -> mercury's home

      # Everything every machine gets (was home.nix).
      misguided.shell # zsh + starship, eza, bat, fzf, zoxide, tmux, fastfetch, direnv…
      misguided.cli # curl, wget, jq, btop, archives, dnsutils…
      misguided.git

      # Languages used to maintain Misguided Framework itself.
      misguided.langs.bash
      misguided.langs.lua
      misguided.langs.markdown
      misguided.langs.nix
      misguided.langs.toml
      misguided.langs.yaml
    ];

    homeManager.programs.git.settings.user = {
      name = "MercNetwork";
      email = "hxnterwelch@icloud.com";
    };

    # NixOS-only account settings. `provides.to-hosts` content reaches every
    # host mercury lives on; its `nixos` part is dropped on Rellana (macOS
    # creates the account itself).
    provides.to-hosts.nixos = {
      # Passwords only come from here; `passwd` changes do not survive a
      # rebuild (or, with impermanence, a reboot).
      users.mutableUsers = false;

      users.users.mercury = {
        description = "Mercury";
        extraGroups = [
          "video"
          "audio"
          "render"
          "input"
        ];
        inherit hashedPassword;
        openssh.authorizedKeys.keys = authorizedKeys;
      };

      # Root keeps a password so the emergency shell is usable, and accepts the
      # same keys so `mcli deploy` / `mcli push` can log in as root.
      users.users.root = {
        inherit hashedPassword;
        openssh.authorizedKeys.keys = authorizedKeys;
      };
    };
  };
}
