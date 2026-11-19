# Intel Arc: media (VA-API / Quick Sync) and compute (OpenCL / Level Zero).
# Enable Resizable BAR / Above 4G Decoding in the BIOS for Arc performance.
{pkgs, ...}: {
  services.xserver.videoDrivers = ["modesetting"];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
      intel-compute-runtime
    ];
  };

  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  hardware.enableRedistributableFirmware = true;
}
