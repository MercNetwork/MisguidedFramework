# Romina (formerly Radahn) — dev laptop and the source of the lab.
# Intel Core i7-11500H (Iris Xe) + NVIDIA RTX 3050 Ti (PRIME offload).
# The rest of the lab is built and pushed from here:
#   mcli switch                          this machine
#   mcli deploy Malenia root@<pi-ip>     first install of the Pi (nixos-anywhere)
#   mcli push Metyr mercury@Metyr        update a server over SSH
{ misguided, ... }:
{
  den.hosts.x86_64-linux.Romina.settings.misguided = {
    disk = {
      device = "/dev/nvme0n1"; # check with `lsblk`
      swapSize = "16G";
      # Travels, so it keeps the LUKS passphrase at boot (no tpmUnlock).
    };
    # MIGRATION: dry run — /persist bind mounts on, nothing wiped. Copy state
    # first (guide, Phase B), then delete this line to turn the wipe on.
    impermanence.wipeRootOnBoot = false;
  };

  den.aspects.Romina = {
    includes = [
      misguided.desktop
      misguided.disk
      misguided.impermanence
      misguided.podman # local containers for dev work (also gives `docker`)

      # mercury's extras on this machine (reach his home via host-aspects)
      misguided.zed
      misguided.flutter
      misguided.langs.cpp
      misguided.langs.docker
      misguided.langs.js
      misguided.langs.python
      misguided.langs.rust
      misguided.langs.web
      misguided.devtools.containers
      misguided.devtools.devbox
      misguided.cli.openssl
      misguided.cli.iperf
      misguided.cli.nmap
    ];

    nixos = {
      imports = [
        ./_hardware-configuration.nix
        ./_nvidia.nix
      ];

      # Build Malenia (aarch64 Raspberry Pi) here under emulation.
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

      # Intel thermal daemon: keeps Tiger Lake CPUs from throttling hard.
      services.thermald.enable = true;
    };
  };
}
