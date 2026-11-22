# misguided.ssh — OpenSSH, key-only, with fail2ban (included by misguided.server).
# mercury's keys: aspects/mercury.nix. Root keys (for mcli deploy/push as root):
# users.users.root.openssh.authorizedKeys.keys in the host's nixos block.
{ misguided, ... }:
{
  misguided.ssh = {
    includes = [ misguided.ssh.allow-users ];

    persist.directories = [ "/var/lib/fail2ban" ];

    nixos = {
      services.openssh = {
        enable = true;
        openFirewall = true;
        # Only the ed25519 key, which misguided-install writes to /persist and
        # impermanence brings back every boot. No RSA key that would be
        # regenerated (and change fingerprint) on each boot.
        hostKeys = [
          {
            type = "ed25519";
            path = "/etc/ssh/ssh_host_ed25519_key";
          }
        ];
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "prohibit-password";
        };
      };

      services.fail2ban = {
        enable = true;
        bantime = "12h";
        bantime-increment = {
          enable = true;
          rndtime = "30m";
        };
      };
    };

    # Naming `user` makes den run this once per user on the host.
    allow-users.nixos =
      { user, ... }:
      {
        services.openssh.settings.AllowUsers = [
          "root"
          user.userName
        ];
      };
  };
}
