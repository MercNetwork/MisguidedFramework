# sops-nix secret management. The age identity is created by misguided-install
# (or generated on first boot) at /etc/sops/identities.txt; the SSH host key
# also works as an identity, so `ssh-to-age` on it gives the host's public key.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.misguided.security.sops;
in {
  imports = [inputs.sops-nix.nixosModules.sops];

  options.misguided.security.sops = {
    enable = lib.mkEnableOption "sops-nix secret management";

    defaultSopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Default encrypted SOPS file for this host.";
    };

    keyFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/sops/identities.txt";
      description = "Path to the age identities file.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.sops pkgs.age pkgs.ssh-to-age];
    environment.sessionVariables.SOPS_AGE_KEY_FILE = cfg.keyFile;

    sops = {
      defaultSopsFile = lib.mkIf (cfg.defaultSopsFile != null) cfg.defaultSopsFile;
      validateSopsFiles = false;
      age = {
        inherit (cfg) keyFile;
        generateKey = true;
        sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      };
    };
  };
}
