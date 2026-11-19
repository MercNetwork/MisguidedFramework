# Whether this host's hosts/<Host>/disko.nix describes its real disks.
#
#   true  (default) — installed with misguided-install / mcli deploy; Disko
#                     generates fileSystems, LUKS and swap from disko.nix.
#   false           — installed some other way (e.g. the graphical installer);
#                     add the filesystems to hardware-configuration.nix instead.
{
  config,
  lib,
  ...
}: {
  options.misguided.disko.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Use hosts/<Host>/disko.nix for filesystems.";
  };

  config.disko.enableConfig = lib.mkDefault config.misguided.disko.enable;
}
