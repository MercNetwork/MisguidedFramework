# `nix flake check` — cheap evaluation checks that the den wiring does what
# the framework expects (adapted from the den example template's tests.nix).
# Each check is a tiny derivation that only builds if its condition holds.
{ config, inputs, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      checkCond = name: cond: pkgs.runCommandLocal name { } (if cond then "touch $out" else "exit 1");
      cfg = host: inputs.self.nixosConfigurations.${host}.config;
      persisted = host: map (d: d.directory) (cfg host).environment.persistence."/persist".directories;
      zedExtensions = (cfg "Romina").home-manager.users.mercury.programs.zed-editor.extensions;
    in
    {
      checks = lib.mapAttrs checkCond {
        # impermanence collects every aspect's `persist` entries
        romina-persists-tailscale = lib.elem "/var/lib/tailscale" (persisted "Romina");
        romina-persists-greeter = lib.elem "/var/lib/cosmic-greeter" (persisted "Romina");
        metyr-persists-immich-db = lib.elem "/var/lib/oci" (persisted "Metyr");
        metyr-skips-desktop-state = !(lib.elem "/var/lib/bluetooth" (persisted "Metyr"));
        # own subvolumes are never bind-mounted over
        malenia-keeps-microvm-subvolume = !(lib.elem "/var/lib/microvms" (persisted "Malenia"));

        # root wipe + disk settings
        # the wipe unit exists exactly when the host's setting asks for it
        romina-wipe-follows-setting =
          ((cfg "Romina").boot.initrd.systemd.services ? misguided-wipe-root)
          == config.den.hosts.x86_64-linux.Romina.settings.misguided.impermanence.wipeRootOnBoot;
        romina-is-encrypted = (cfg "Romina").boot.initrd.luks.devices ? cryptroot;
        romina-asks-passphrase = !(lib.elem "tpm2-device=auto" (cfg "Romina").boot.initrd.luks.devices.cryptroot.crypttabExtraOpts);
        midra-unlocks-with-tpm = lib.elem "tpm2-device=auto" (cfg "Midra").boot.initrd.luks.devices.cryptroot.crypttabExtraOpts;
        metyr-is-not-encrypted = (cfg "Metyr").boot.initrd.luks.devices == { };
        metyr-has-services-subvolume = (cfg "Metyr").fileSystems ? "/mnt/services";

        # sops reads its key from /persist on impermanent hosts
        metyr-sops-key-on-persist = (cfg "Metyr").sops.age.keyFile == "/persist/etc/sops/identities.txt";

        # host aspects reach mercury's home (den.batteries.host-aspects) and the
        # zedExtensions quirk sees both host-level and user-level languages
        romina-zed-extensions = lib.all (e: lib.elem e zedExtensions) [
          "basher" # langs.bash, included by mercury
          "dockerfile" # langs.docker, included by Romina
          "dart" # flutter, included by Romina
          "sql" # cli, included by mercury
        ];
        metyr-has-no-zed = !(cfg "Metyr").home-manager.users.mercury.programs.zed-editor.enable;

        # per-user fan-out (transmission adds mercury to its group)
        metyr-mercury-in-transmission = lib.elem "transmission" (cfg "Metyr").users.users.mercury.extraGroups;
      };
    };
}
