# microvm.nix host: declarative NixOS VMs managed as systemd services.
#
#   misguided.virtualisation.microvm.vms.<name> = {
#     autostart = true;
#     config = { ... a NixOS config with a `microvm = { ... }` block ... };
#   };
#
#   systemctl status microvm@<name>     journalctl -u microvm@<name>
#   microvm -l                          (list VMs and whether they're outdated)
{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.misguided.virtualisation.microvm;
  enabledVms = lib.filterAttrs (_: vm: vm.enable) cfg.vms;
in {
  imports = [inputs.microvm.nixosModules.host];

  options.misguided.virtualisation.microvm = {
    enable = lib.mkEnableOption "the microvm.nix hypervisor host";

    vms = lib.mkOption {
      default = {};
      description = "Declarative MicroVM guests.";
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Build and run this MicroVM.";
          };

          autostart = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Start this MicroVM when the host boots.";
          };

          restartIfChanged = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Restart the MicroVM when its configuration changes.";
          };

          config = lib.mkOption {
            type = lib.types.deferredModule;
            default = {};
            description = "NixOS configuration of the guest.";
          };

          extraModules = lib.mkOption {
            type = lib.types.listOf lib.types.deferredModule;
            default = [];
            description = "Additional NixOS modules for the guest.";
          };

          specialArgs = lib.mkOption {
            type = lib.types.attrs;
            default = {};
            description = "Extra specialArgs for the guest's module evaluation.";
          };
        };
      });
    };
  };

  config = lib.mkMerge [
    {microvm.host.enable = cfg.enable;}

    (lib.mkIf cfg.enable {
      microvm.vms =
        lib.mapAttrs (_: vm: {
          inherit (vm) autostart restartIfChanged config extraModules specialArgs;
        })
        enabledVms;

      # VM state directories must exist before install-microvm-*.service runs.
      system.activationScripts.microvm-dirs = ''
        mkdir -p "${config.microvm.stateDir}"
        chown microvm:kvm "${config.microvm.stateDir}"
        chmod 0775 "${config.microvm.stateDir}"
        ${lib.concatLines (lib.mapAttrsToList (name: _: ''
            mkdir -p "${config.microvm.stateDir}/${name}"
            chown microvm:kvm "${config.microvm.stateDir}/${name}"
            chmod 0775 "${config.microvm.stateDir}/${name}"
          '')
          enabledVms)}
      '';

      misguided.user.extraGroups = ["kvm"];
    })
  ];
}
