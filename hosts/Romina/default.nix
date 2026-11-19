# Romina (formerly Radahn) — dev laptop and the source of the lab.
# Intel Core i7-11500H (Iris Xe) + NVIDIA RTX 3050 Ti (PRIME offload).
# The rest of the lab is built and pushed from here:
#   mcli switch                          this machine
#   mcli deploy Malenia root@<pi-ip>     first install of the Pi (nixos-anywhere)
#   mcli push Metyr mercury@Metyr        update a server over SSH
{...}: {
  imports = [
    ../common/desktop.nix
    ./hardware-configuration.nix
    ./disko.nix
    ./nvidia.nix
  ];

  # Build Malenia (aarch64 Raspberry Pi) here under emulation.
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  # Intel thermal daemon: keeps Tiger Lake CPUs from throttling hard.
  services.thermald.enable = true;

  # Local containers for dev work (also gives `docker` via podman).
  misguided.virtualisation.podman.enable = true;

  misguided.user.home = {
    misguided = {
      zed.enable = true;
      flutter.enable = true;

      langs = {
        cpp.enable = true;
        docker.enable = true;
        js.enable = true;
        python.enable = true;
        rust.enable = true;
        web.enable = true;
      };

      devtools = {
        containers.enable = true;
        devbox.enable = true;
      };

      cli = {
        openssl.enable = true;
        iperf.enable = true;
        nmap.enable = true;
      };
    };
  };
}
