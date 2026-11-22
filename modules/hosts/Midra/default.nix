# Midra (formerly Malenia) — desktop. AMD Ryzen + Intel Arc. Keeps the gaming stack.
# COSMIC desktop; rebuilt from Romina with `mcli push Midra mercury@midra`.
{ misguided, ... }:
{
  den.hosts.x86_64-linux.Midra.settings.misguided.disk = {
    device = "/dev/nvme0n1"; # check with `lsblk`
    # Still encrypted, but the TPM unlocks it at boot, so Midra can be rebooted
    # remotely. Romina (travels) is the only machine that asks for a passphrase.
    # One-time, on Midra:  sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-partlabel/luks
    tpmUnlock = true;
  };

  den.aspects.Midra = {
    includes = [
      misguided.desktop
      misguided.disk
      misguided.impermanence
      misguided.gaming
      misguided.ssh # key-only SSH, so Romina can `mcli push Midra mercury@midra`
    ];

    nixos =
      { pkgs, ... }:
      {
        imports = [
          ./_hardware-configuration.nix
          ./_intel-arc.nix
        ];

        # Arc (Battlemage) runs on the `xe` driver, which wants a recent kernel.
        boot.kernelPackages = pkgs.linuxPackages_latest;
      };
  };
}
