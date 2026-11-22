# misguided.microvm-host — microvm.nix host: declarative NixOS VMs managed as
# systemd services. Guests are plain microvm.nix options in the host's nixos
# block (see hosts/Malenia):
#
#   microvm.vms.<name> = { autostart = true; config = { … a `microvm = { … }` block … }; };
#
#   systemctl status microvm@<name>     journalctl -u microvm@<name>
#   microvm -l                          (list VMs and whether they're outdated)
#
# Guest state lives in /var/lib/microvms. On Malenia that is its own @microvm
# subvolume, so it is NOT listed under `persist` (a bind mount would hide the
# subvolume). On a host without that subvolume, add it to the host's persist.
{ inputs, misguided, ... }:
{
  flake-file.inputs.microvm = {
    url = "github:microvm-nix/microvm.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  misguided.microvm-host = {
    includes = [ misguided.microvm-host.user-group ];

    nixos =
      { config, lib, ... }:
      {
        imports = [ inputs.microvm.nixosModules.host ];

        microvm.host.enable = true;

        # VM state directories must exist before install-microvm-*.service runs.
        system.activationScripts.microvm-dirs = ''
          mkdir -p "${config.microvm.stateDir}"
          chown microvm:kvm "${config.microvm.stateDir}"
          chmod 0775 "${config.microvm.stateDir}"
          ${lib.concatLines (
            lib.mapAttrsToList (name: _: ''
              mkdir -p "${config.microvm.stateDir}/${name}"
              chown microvm:kvm "${config.microvm.stateDir}/${name}"
              chmod 0775 "${config.microvm.stateDir}/${name}"
            '') config.microvm.vms
          )}
        '';
      };

    user-group.nixos =
      { user, ... }:
      {
        users.users.${user.userName}.extraGroups = [ "kvm" ];
      };
  };
}
