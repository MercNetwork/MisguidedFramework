# Misguided Framework

mercury's NixOS / nix-darwin homelab flake, built on [den](https://den.denful.dev).
Every file under `modules/` is a module
(loaded by import-tree); `flake.nix` is generated from them by flake-file.

| Host | Was | Hardware | Role |
|------|-----|----------|------|
| `Romina` | Radahn | i7-11500H + RTX 3050 Ti laptop | Dev laptop, source of the lab. COSMIC, Zed, Flutter. LUKS passphrase at boot |
| `Midra` | Malenia | Ryzen + Intel Arc desktop | COSMIC desktop + gaming (Steam). LUKS unlocked by TPM |
| `Metyr` | Morgott | x86_64 server | Homelab: Caddy, AdGuard, Immich, Jellyfin, Transmission, Syncthing… |
| `Malenia` | Godrick | Raspberry Pi 5, 8 GB | Headless microvm.nix VM/container host |
| `Rellana` | Mohg | Apple Silicon Mac | nix-darwin, shell + dev tools |

Every NixOS host is **impermanent**: `/` (the Btrfs `@` subvolume) is recreated
on every boot. `/home`, `/nix`, `/persist` and service subvolumes are kept, and
each feature lists the system paths it needs under `persist`.

Login on every NixOS host: `mercury` / `chloe`. Change the hash in
`modules/aspects/mercury.nix` (`mkpasswd -m sha-512`).

```bash
mcli switch               # apply changes on this machine
mcli update               # update pinned inputs
nix run .#write-flake     # after adding/changing any flake-file.inputs
nix flake check           # evaluate every machine
mcli seed | sudo bash     # impermanence migration: copy this host's state into /persist
```

## Layout

```
flake.nix                       GENERATED (nix run .#write-flake) — don't edit
modules/
  den.nix                       the fleet: one line per machine
  inputs.nix                    core inputs (others sit next to the aspect that uses them)
  namespace.nix                 the `misguided` aspect namespace
  settings.nix                  typed per-host settings (host.settings.misguided.*)
  dendritic.nix                 dendritic flake-parts + flake-file
  tools.nix                     mcli, misguided-install, misguided-recover, devShell, formatter
  aspects/
    defaults.nix                den.default: state versions, hostname, define-user, HM settings
    mercury.nix                 the user (was hosts/common/user.nix + home.nix)
    misguided/                  every feature, as an aspect:
      base desktop server       roles (was hosts/common/*)
      disk impermanence         the shared Btrfs layout + root wipe + persistence collector
      cosmic gaming tailscale
      niri/                     opt-in niri session next to COSMIC (niri.nix + its configs)
      server/                   ssh sops adguard caddy cloudflared syncthing transmission wireguard
      oci/                      immich jellyfin pgadmin
      virtualisation/           podman docker oci compose2nix microvm-host
      home/                     shell cli git langs zed flutter devtools
      darwin/                   misguided.darwin (+ .defaults .homebrew .tailscale .screen-sharing)
  hosts/<Host>/                 default.nix (host settings + den.aspects.<Host>) + _hardware files
installer/                      mcli.sh, install.sh, recover.sh
Wallpapers/                     -> ~/Pictures/Wallpapers on the desktops
```

### How the pieces talk

- **A host includes features.** `den.aspects.Romina.includes = [ misguided.desktop misguided.zed … ];`
  There are no `misguided.*.enable` options anymore: included = on.
- **Host values are settings.** `den.hosts.x86_64-linux.Romina.settings.misguided.disk.device = "/dev/nvme0n1";`
- **Host home additions** go in a host's `homeManager` block or come from aspects it
  includes; `den.batteries.host-aspects` (in mercury.nix) carries them to mercury.
- **Persistence** is declared by the feature that needs it:
  `misguided.tailscale.persist.directories = [ "/var/lib/tailscale" ];`
- **Zed extensions** are declared by the language that needs them:
  `zedExtensions = [ "basher" ];` on `misguided.langs.bash`.

## Installing

**Romina, Midra, Metyr**: boot the NixOS ISO, then:

```bash
git clone https://github.com/MercNetwork/MisguidedFramework ~/MisguidedFramework && cd ~/MisguidedFramework
sudo nix --extra-experimental-features "nix-command flakes" run .#install -- Romina
```

This formats the disk set in `modules/hosts/<Host>/default.nix`
(`settings.misguided.disk.device` — check with `lsblk` first), installs, seeds
`/persist`, and copies the repo to `~/MisguidedFramework`. Romina and Midra use LUKS.
Romina asks for the passphrase at boot (it travels). Midra unlocks with its TPM
(`settings.misguided.disk.tpmUnlock`) after a one-time enrollment on the machine:
`sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-partlabel/luks`.
Metyr and Malenia aren't encrypted, so every machine except Romina comes back on its own.
Regenerate `_hardware-configuration.nix` on real hardware with
`nixos-generate-config --no-filesystems --show-hardware-config`. Metyr's is a placeholder.

**Malenia (Pi 5)**: boot the nixos-raspberrypi installer from SD, add your SSH
key to `modules/aspects/mercury.nix`, then from Romina:

```bash
mcli deploy Malenia root@<pi-ip>     # nixos-anywhere + disko onto NVMe/USB
mcli push Malenia mercury@Malenia    # later updates
```

Malenia is built with nixos-raspberrypi's own `nixosSystem` (their nixpkgs
release and binary cache) and Home Manager's matching release branch.

**Rellana**: install Nix, clone to `~/MisguidedFramework`, then
`sudo nix run nix-darwin -- switch --flake ~/MisguidedFramework#Rellana`.

## Remote access

Every machine is on Tailscale (`sudo tailscale up` once per machine).

| From | How | Address |
|---|---|---|
| Romina → Midra, Metyr, Malenia | SSH (keys only); rebuild with `mcli push <Host> mercury@<host>` | `mercury@midra`, … |
| iPhone → any SSH host | an SSH client (Termius, Blink) — add its key to `mercury.nix` | `mercury@metyr` |
| iPhone → Rellana desktop | a VNC client (Screens, RealVNC Viewer) | `rellana:5900` |
| iPhone → Metyr services | Safari / Immich / Jellyfin apps | `metyr:2283`, `metyr:8096`, … |

COSMIC has no built-in remote desktop server yet, so there's no RDP into
Romina or Midra for now.

## niri (optional second session)

`misguided.niri` adds [niri](https://github.com/YaLTeR/niri) as a second session on
a desktop host; COSMIC stays the default. Add it to the host's `includes` (the line
is already there, commented out, on Romina and Midra), rebuild, log out, and pick
**Niri** on the login screen.

It's the [endeavouros-niri](https://gitlab.com/trungdaohieutrung/endeavouros-niri)
setup (waybar, fuzzel, its keybinds and look) running on COSMIC's pieces: COSMIC's
lock screen, idle/screen-off, wallpaper, notifications and polkit prompts, and
COSMIC Terminal / Files / Text Editor / System Monitor / Settings as the apps.
Settings you change in COSMIC (wallpaper, theme, Power timings) apply to both
sessions. Keybinds: `Mod+Shift+/` in niri, or `modules/aspects/misguided/niri/conf/binds.kdl`.

## Impermanence notes

- Something vanished after a reboot? It wasn't listed under any `persist`.
  The last 30 days of roots are kept: `sudo mount -o subvol=/ /dev/disk/by-label/Nixos-root /mnt`
  and look in `/mnt/old_roots/`. Then add the path to the aspect that owns it.
- `settings.misguided.impermanence.wipeRootOnBoot = false;` on a host keeps the
  bind mounts but stops the wipe (useful while migrating).
- `/home` is not wiped.
