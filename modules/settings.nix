# Typed per-host tunables. An aspect declares `settings.<name> = mkOption …`
# next to its config; a host sets `settings.<aspect path>.<name>`; class
# modules read `host.settings.<aspect path>.<name>`.
#
# This replaces the old `misguided.*` NixOS options for the few values that
# really differ per machine (disk device, swap size, encryption…). Everything
# else is an aspect a host either includes or doesn't.
{ den, lib, ... }:
{
  den.reservedKeys = [ "settings" ];

  den.schema.host.imports = [
    {
      options.settings = lib.mkOption {
        type = import ./_settings-type.nix { inherit den lib; };
        default = { };
        description = "Per-aspect typed settings";
      };
    }
  ];
}
