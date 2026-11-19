# Intel iGPU drives the screen; the RTX 3050 Ti sleeps until asked for.
# Run something on the NVIDIA GPU with:  nvidia-offload <program>
{
  config,
  pkgs,
  ...
}: {
  nixpkgs.config.nvidia.acceptLicense = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # VA-API (iHD)
      vpl-gpu-rt # Quick Sync
      intel-compute-runtime # OpenCL / Level Zero
    ];
  };

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    # Open kernel modules: Turing (RTX 20) and newer, so fine for the 3050 Ti.
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Lets the dGPU power off when idle (needed for decent battery life).
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # Verify on the machine: `lspci | grep -E "VGA|3D"`
      #   00:02.0 -> "PCI:0:2:0"   01:00.0 -> "PCI:1:0:0"
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
