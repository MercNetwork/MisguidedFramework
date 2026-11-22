# misguided.syncthing — Syncthing, running as the host's user. Web UI on
# http://127.0.0.1:8384 (reach it over SSH/Tailscale:
# `ssh -L 8384:localhost:8384 mercury@Metyr`). Its config and data are in
# the user's home, which is on @home, so nothing to persist.
{
  # Naming `user` makes den run this once per user on the host.
  misguided.syncthing.nixos =
    { user, ... }:
    {
      services.syncthing = {
        enable = true;
        user = user.userName;
        group = "users";
        dataDir = "/home/${user.userName}";
        configDir = "/home/${user.userName}/.config/syncthing";
        openDefaultPorts = true;
      };
    };
}
