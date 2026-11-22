# misguided.oci — declarative containers (virtualisation.oci-containers), used
# by misguided.immich / jellyfin / pgadmin. Runs on Docker if the host has
# misguided.docker, otherwise Podman.
{ misguided, ... }:
{
  misguided.oci.nixos =
    { host, ... }:
    {
      virtualisation.oci-containers.backend =
        if host.hasAspect misguided.docker then "docker" else "podman";

      # Scratch dir the containers use as TMPDIR (under the persisted
      # /var/lib/containers on podman hosts; recreated on boot otherwise).
      systemd.tmpfiles.rules = [ "d /var/lib/containers/tmp 1777 root root -" ];
    };
}
