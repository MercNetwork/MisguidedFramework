# OpenSSH, key-only, with fail2ban. Keys come from misguided.user.authorizedKeys.
{
  config,
  lib,
  ...
}: let
  cfg = config.misguided.services.ssh;
  user = config.misguided.user.name;
in {
  options.misguided.services.ssh = {
    enable = lib.mkEnableOption "OpenSSH (key-only) with fail2ban";

    port = lib.mkOption {
      type = lib.types.port;
      default = 22;
      description = "SSH server port.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the SSH port in the firewall.";
    };

    allowedUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["root" user];
      description = "Users allowed to connect via SSH.";
    };

    rootAuthorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "SSH public keys for root (mcli deploy/push can use these).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      inherit (cfg) openFirewall;
      ports = [cfg.port];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "prohibit-password";
        AllowUsers = cfg.allowedUsers;
      };
    };

    users.users.root.openssh.authorizedKeys.keys = cfg.rootAuthorizedKeys;

    services.fail2ban = {
      enable = true;
      bantime = "12h";
      bantime-increment = {
        enable = true;
        rndtime = "30m";
      };
    };
  };
}
