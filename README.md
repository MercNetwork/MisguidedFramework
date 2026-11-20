# Misguided Framework

mercury's NixOS / nix-darwin homelab flake. Plain flake (no flake-parts), one
folder per machine under `hosts/`, shared pieces in `hosts/common/`, and
switchable features in `modules/` as `misguided.*` options.

| Host | Was | Hardware | Role |
|------|-----|----------|------|
| `Romina` | Radahn | i7-11500H + RTX 3050 Ti laptop | Dev laptop, source of the lab. GNOME, Zed, Flutter |
| `Midra` | Malenia | Ryzen + Intel Arc desktop | GNOME desktop + gaming (Steam) |
| `Metyr` | Morgott | x86_64 server | Homelab: Caddy, AdGuard, Immich, Jellyfin, Transmission, Syncthing… |
| `Malenia` | Godrick | Raspberry Pi 5, 8 GB | Headless microvm.nix VM/container host |
| `Rellana` | Mohg | Apple Silicon Mac | nix-darwin, shell + dev tools |

Login on every NixOS host: `mercury` / `chloe`. Change the hash in
`hosts/common/user.nix` (`mkpasswd -m sha-512`).

```bash
mcli switch          # apply changes on this machine
mcli update          # update pinned inputs (also locks new ones)
mcli build           # build and show what would change
mcli help            # everything else
```

## Layout

```
flake.nix                 inputs + one line per machine (mkHost)
home.nix                  mercury's Home Manager config for every machine
Wallpapers/               your images -> ~/Pictures/Wallpapers on the desktops
installer/                mcli, misguided-install (disko), misguided-recover
hosts/
  common/base.nix         every NixOS host: boot, nix, locale, Home Manager
  common/user.nix         the mercury user (misguided.user.*)
  common/desktop.nix      vanilla GNOME desktops: audio, fonts, Firefox, Discord, Fragments
  common/server.nix       headless: SSH (keys only), nftables, sops
  Romina/ Midra/ Metyr/   default.nix + disko.nix + hardware-configuration.nix (+ GPU file)
  Malenia/                Pi 5: default.nix + disko.nix (board support from nixos-raspberrypi)
  Rellana/                nix-darwin
modules/
  nixos/gnome.nix         GNOME + GDM — the full app list to exclude from is here
  nixos/remote-desktop.nix  GNOME Remote Login (RDP) for Midra and Romina
  nixos/tailscale.nix     Tailscale, on every NixOS machine
  nixos/gaming.nix        Steam, ProtonPlus, GameMode
  nixos/server/           ssh, caddy, adguard, cloudflared, syncthing, transmission, wireguard
  nixos/oci/              immich, jellyfin, pgadmin (containers)
  nixos/virtualisation/   podman, docker, oci, compose2nix, microvm
  nixos/sops.nix          sops-nix
  home/                   shell, cli, git, langs, zed, flutter, devtools, desktop
  darwin/                 Rellana's base, macOS defaults, Homebrew, Tailscale + Screen Sharing
```

Per-host Home Manager additions go in the host file:

```nix
misguided.user.home.misguided.langs.go.enable = true;
```

## Installing

**Romina, Midra, Metyr**: boot the NixOS ISO, then:

```bash
git clone https://github.com/MercNetwork/MisguidedFramework ~/MisguidedFramework && cd ~/MisguidedFramework
sudo nix --extra-experimental-features "nix-command flakes" run .#install -- Romina
```

This formats the disk in `hosts/<Host>/disko.nix` (check `device` with `lsblk`
first), installs, and copies the repo to `~/MisguidedFramework`. Romina and Midra use
LUKS (passphrase at boot); Metyr doesn't, so it comes back on its own after a
power cut. Regenerate `hardware-configuration.nix` on real hardware with
`nixos-generate-config --no-filesystems --show-hardware-config`. Metyr's is a placeholder.

**Malenia (Pi 5)**: build or download the `rpi5` installer image from
[nvmd/nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi), boot it
from SD, add your SSH key to `hosts/common/server.nix`, then from Romina:

```bash
mcli deploy Malenia root@<pi-ip>     # nixos-anywhere + disko onto NVMe/USB
mcli push Malenia mercury@Malenia    # later updates
```

**Metyr** can be installed the same way (`mcli deploy Metyr root@<ip>`) from
any NixOS ISO with SSH enabled.

**Rellana**: install Nix, clone to `~/MisguidedFramework`, then
`sudo nix run nix-darwin -- switch --flake ~/MisguidedFramework#Rellana`.

## Remote access

Every machine is on Tailscale (`sudo tailscale up` once per machine). On the
tailnet, your iPhone included, every port is reachable. Nothing extra is
opened on the LAN.

| From the iPhone | App | Address |
|---|---|---|
| Midra, Romina desktop | Windows App (RDP) | `midra`, `romina` |
| Rellana desktop | a VNC client (Screens, RealVNC Viewer) | `rellana:5900` |
| Metyr services | Safari / Immich / Jellyfin apps | `metyr:2283`, `metyr:8096`, … |
| Any shell | an SSH client (Termius, Blink) | `mercury@metyr` |

Remote Desktop needs a one-time RDP login on Midra and Romina:

```bash
sudo grdctl --system rdp set-credentials <rdp-user> <rdp-password>
sudo grdctl --system rdp enable
```

## First boot

- Set your own password hash in `hosts/common/user.nix`.
- Servers: put your SSH public key in `hosts/common/server.nix` **before**
  deploying (SSH is key-only), then `sudo tailscale up`.
- Romina: `flutter doctor` (Linux desktop target only; Android/Chrome show as
  missing on purpose), and check the PRIME bus IDs in `hosts/Romina/nvidia.nix` with `lspci`.
- Fragments: Preferences → connect to `Metyr`, port 9091 (Transmission on Metyr).
- Writing an ISO to USB: GNOME Disks → ⋮ → Restore Disk Image.
- Metyr: tighten `allowedSubnets` for AdGuard, and move Immich's database
  password into sops before exposing anything.
