# misguided.sops — sops-nix secret management (included by misguided.server).
#
# The age identity is created by misguided-install at /persist/etc/sops/identities.txt;
# the SSH host key also works as an identity, so `ssh-to-age` on it gives the
# host's public key. On an impermanent host, sops-nix decrypts during
# activation — before the /persist bind mounts exist — so it reads both keys
# straight from /persist.
#
# Default secrets file for a host: sops.defaultSopsFile = ./secrets.yaml; in the
# host's nixos block.
{ inputs, misguided, ... }:
{
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  misguided.sops = {
    persist.directories = [ "/etc/sops" ];

    nixos =
      { host, pkgs, ... }:
      let
        prefix = if host.hasAspect misguided.impermanence then "/persist" else "";
        keyFile = "${prefix}/etc/sops/identities.txt";
      in
      {
        imports = [ inputs.sops-nix.nixosModules.sops ];

        environment.systemPackages = [
          pkgs.sops
          pkgs.age
          pkgs.ssh-to-age
        ];
        environment.sessionVariables.SOPS_AGE_KEY_FILE = keyFile;

        sops = {
          validateSopsFiles = false;
          age = {
            inherit keyFile;
            generateKey = true;
            sshKeyPaths = [ "${prefix}/etc/ssh/ssh_host_ed25519_key" ];
          };
        };
      };
  };
}
