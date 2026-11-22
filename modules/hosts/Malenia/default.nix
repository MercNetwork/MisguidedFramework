# Malenia (formerly Godrick) — Raspberry Pi 5, 8 GB. Headless VM/container host
# running microvm.nix guests. Board support (kernel, firmware, bootloader) comes
# from nvmd/nixos-raspberrypi.
#
# Install from Romina (the Pi boots the nixos-raspberrypi installer from SD):
#   mcli deploy Malenia root@<pi-ip>
# Update later:
#   mcli push Malenia mercury@Malenia
#
# Guests: add them under microvm.vms below. Each one gets a tap interface
# (vm-*) on bridge br0, so it pulls its own IP from your router.
# Check KVM after first boot:  ls -l /dev/kvm
#
# Page size: the Pi 5 kernel can run 16K pages (raspberry-pi-5.page-size-16k)
# for a little extra speed, but some container images and VM guests built for
# 4K pages crash on it. Left at 4K for a container/VM host.
#
# Disk: NVMe on a Pi 5 HAT (/dev/nvme0n1) or a USB SSD (/dev/sda) — NOT the SD
# card the installer runs from. If it won't boot from NVMe, set the EEPROM boot
# order once from Pi OS:  sudo rpi-eeprom-config --edit  ->  BOOT_ORDER=0xf416
{ inputs, misguided, ... }:
{
  # Deliberately NOT following our nixpkgs so the Pi kernel comes from their cache.
  flake-file.inputs.nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

  # Home Manager release matching nixos-raspberrypi's nixpkgs (see `instantiate`).
  # Bump the branch together with nixos-raspberrypi's nixpkgs release.
  flake-file.inputs.home-manager-rpi = {
    url = "github:nix-community/home-manager/release-26.05";
    inputs.nixpkgs.follows = "nixos-raspberrypi/nixpkgs";
  };

  den.hosts.aarch64-linux.Malenia = {
    # Built with nixos-raspberrypi's own nixosSystem: THEIR nixpkgs (a stable
    # release the Pi kernel is tested and cached against), their overlays, the
    # `nixos-raspberrypi` module argument and their binary cache. Our
    # nixos-unstable is ahead of what the Pi kernel packaging supports.
    instantiate = inputs.nixos-raspberrypi.lib.nixosSystem;
    home-manager.module = inputs.home-manager-rpi.nixosModules.home-manager;

    settings.misguided.disk = {
      device = "/dev/nvme0n1";
      boot = "rpi";
      # No disk encryption: a headless Pi can't ask for a passphrase at boot.
      encrypt = false;
      swapSize = "4G";
      # nodatacow: VM disk images fragment badly under copy-on-write. Own
      # subvolume, so guest volumes survive the root wipe.
      extraSubvolumes."@microvm" = {
        mountpoint = "/var/lib/microvms";
        mountOptions = [
          "noatime"
          "nodatacow"
        ];
      };
    };
  };

  den.aspects.Malenia = {
    includes = [
      misguided.server
      misguided.disk
      misguided.impermanence
      misguided.microvm-host
    ];

    nixos =
      { lib, ... }:
      {
        imports = with inputs.nixos-raspberrypi.nixosModules; [
          raspberry-pi-5.base
          raspberry-pi-5.bluetooth
          # raspberry-pi-5.page-size-16k  # see the note at the top before enabling
        ];

        # The Pi modules bring their own bootloader (no UEFI / systemd-boot).
        boot.loader.systemd-boot.enable = lib.mkForce false;
        boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
        boot.loader.raspberry-pi.bootloader = "kernel"; # generational, recommended for new installs

        # --- Networking: systemd-networkd with a bridge for the VMs ---
        # Wired Ethernet only (Wi-Fi can't be bridged).
        networking.networkmanager.enable = false;
        networking.useNetworkd = true;
        networking.useDHCP = false;
        systemd.network = {
          enable = true;
          netdevs."10-br0".netdevConfig = {
            Kind = "bridge";
            Name = "br0";
          };
          networks = {
            # Ethernet (end0 on the Pi 5) and every microvm tap join the bridge.
            "10-lan" = {
              matchConfig.Name = [
                "en*"
                "eth*"
                "vm-*"
              ];
              networkConfig.Bridge = "br0";
              linkConfig.RequiredForOnline = "enslaved";
            };
            # The host itself gets its address on br0.
            "20-br0" = {
              matchConfig.Name = "br0";
              networkConfig.DHCP = "yes";
              linkConfig.RequiredForOnline = "routable";
            };
          };
        };

        # --- microvm.nix guests ---
        # Template guest — uncomment, rename, give it a unique MAC.
        # microvm.vms.example = {
        #   autostart = true;
        #   config = {
        #     microvm = {
        #       hypervisor = "qemu";
        #       vcpu = 1;
        #       mem = 1024;
        #       interfaces = [
        #         {
        #           type = "tap";
        #           id = "vm-example"; # must start with vm- (see the bridge above), max 15 chars
        #           mac = "02:00:00:00:00:01";
        #         }
        #       ];
        #       # Share the host's /nix/store read-only — tiny guest images.
        #       shares = [
        #         {
        #           proto = "virtiofs";
        #           tag = "ro-store";
        #           source = "/nix/store";
        #           mountPoint = "/nix/.ro-store";
        #         }
        #       ];
        #     };
        #     networking.hostName = "example";
        #     systemd.network.enable = true;
        #     networking.useNetworkd = true;
        #     services.openssh.enable = true;
        #     system.stateVersion = "26.05";
        #   };
        # };
      };
  };
}
