# Malenia (formerly Godrick) — Raspberry Pi 5, 8 GB. Headless VM/container host
# running microvm.nix guests. Board support (kernel, firmware, bootloader) comes
# from nvmd/nixos-raspberrypi, wired in flake.nix.
#
# Install from Romina (the Pi boots the nixos-raspberrypi installer from SD):
#   mcli deploy Malenia root@<pi-ip>
# Update later:
#   mcli push Malenia mercury@Malenia
#
# Guests: add them under misguided.virtualisation.microvm.vms below. Each one gets
# a tap interface (vm-*) on bridge br0, so it pulls its own IP from your router.
# Check KVM after first boot:  ls -l /dev/kvm
#
# Page size: the Pi 5 kernel can run 16K pages (raspberry-pi-5.page-size-16k in
# flake.nix) for a little extra speed, but some container images and VM guests
# built for 4K pages crash on it. Left at 4K for a container/VM host.
{lib, ...}: {
  imports = [
    ../common/server.nix
    ./disko.nix
  ];

  # The Pi modules bring their own bootloader (no UEFI / systemd-boot).
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.raspberry-pi.bootloader = "kernel"; # generational, recommended for new installs

  # Kernel + firmware from the nixos-raspberrypi binary cache instead of building on the Pi.
  nix.settings = {
    extra-substituters = ["https://nixos-raspberrypi.cachix.org"];
    extra-trusted-public-keys = ["nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="];
  };

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
        matchConfig.Name = ["en*" "eth*" "vm-*"];
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

  # --- microvm.nix host ---
  misguided.virtualisation.microvm = {
    enable = true;

    vms = {
      # Template guest — copy it, rename, give it a unique MAC, set enable = true.
      example = {
        enable = false;
        autostart = true;
        config = {
          microvm = {
            hypervisor = "qemu";
            vcpu = 1;
            mem = 1024;
            interfaces = [
              {
                type = "tap";
                id = "vm-example"; # must start with vm- (see the bridge above), max 15 chars
                mac = "02:00:00:00:00:01";
              }
            ];
            # Share the host's /nix/store read-only — tiny guest images.
            shares = [
              {
                proto = "virtiofs";
                tag = "ro-store";
                source = "/nix/store";
                mountPoint = "/nix/.ro-store";
              }
            ];
          };

          networking.hostName = "example";
          systemd.network.enable = true;
          networking.useNetworkd = true;
          services.openssh.enable = true;
          system.stateVersion = "26.05";
        };
      };
    };
  };
}
