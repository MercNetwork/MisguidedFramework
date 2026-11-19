# Declarative containers (virtualisation.oci-containers), used by modules/nixos/oci/*.
# Runs on Docker if it's enabled, otherwise Podman.
{
  config,
  lib,
  ...
}: let
  cfg = config.misguided.virtualisation.oci;
in {
  options.misguided.virtualisation.oci.enable = lib.mkEnableOption "oci-containers backend";

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.backend =
      if config.misguided.virtualisation.docker.enable
      then "docker"
      else "podman";

    # Scratch dir the containers in modules/nixos/oci/* use as TMPDIR.
    systemd.tmpfiles.rules = ["d /var/lib/containers/tmp 1777 root root -"];
  };
}
