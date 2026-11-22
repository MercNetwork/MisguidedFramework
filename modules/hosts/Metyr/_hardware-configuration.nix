# Metyr hardware — PLACEHOLDER (generic x86_64 box with an NVMe/SATA disk).
# Replace on the real machine before installing:
#   sudo nixos-generate-config --no-filesystems --show-hardware-config
# (--no-filesystems because Disko owns them — see ./disko.nix.)
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = []; # add "kvm-intel" or "kvm-amd"
  boot.extraModulePackages = [];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
