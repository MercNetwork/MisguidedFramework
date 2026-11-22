#!/usr/bin/env bash
set -euo pipefail

# misguided-install — partition, format and install a Misguided Framework NixOS host.
#
#   sudo misguided-install <host> [flake]
#
#   <host>   a nixosConfigurations name (Romina, Midra, Metyr — see modules/den.nix)
#   [flake]  path or URI of the Misguided Framework flake (default: current directory)
#
# Run it from the NixOS live ISO, inside a clone of the repo:
#   git clone https://github.com/MercNetwork/MisguidedFramework ~/MisguidedFramework && cd ~/MisguidedFramework
#   sudo nix --extra-experimental-features "nix-command flakes" run .#install -- Romina
#
# Malenia (Pi 5) is installed remotely instead:  mcli deploy Malenia root@<pi-ip>

HOST="${1:-}"
FLAKE="${2:-.}"

if [ -z "${HOST}" ]; then
  echo "Usage: misguided-install <host> [flake]"
  echo ""
  echo "Hosts using misguided.disk: Romina, Midra, Metyr"
  echo "(Malenia: mcli deploy Malenia root@<ip>   Rellana: see README)"
  echo ""
  echo "Example (from inside the repo on the live ISO):"
  echo "  sudo nix run .#install -- Romina"
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: misguided-install must be run as root (or via sudo)." >&2
  exit 1
fi

echo "=================================================="
echo " Misguided Framework installer"
echo " Target host: ${HOST}"
echo " Flake:       ${FLAKE}"
echo "=================================================="
echo ""
echo "WARNING: This repartitions and FORMATS the disk set in"
echo "modules/hosts/${HOST}/default.nix (settings.misguided.disk.device)."
echo "Everything on that disk will be erased."
echo ""
read -r -p "Type the host name (${HOST}) to continue: " confirm
if [ "${confirm}" != "${HOST}" ]; then
  echo "Installation aborted."
  exit 0
fi

# 1. Partition and format
echo "--> [1/6] Running Disko for ${HOST}..."
disko --mode destroy,format,mount --flake "${FLAKE}#${HOST}"

# 2. Host identity (SSH host key + SOPS age identity)
echo "--> [2/6] Creating host keys..."
mkdir -p /mnt/persist/etc/ssh /mnt/persist/etc/sops

if [ ! -f /mnt/persist/etc/ssh/ssh_host_ed25519_key ]; then
  ssh-keygen -t ed25519 -N "" -C "root@${HOST}" -f /mnt/persist/etc/ssh/ssh_host_ed25519_key
fi

if [ -n "${AGE_IDENTITY:-}" ]; then
  printf '%s\n' "${AGE_IDENTITY}" >/mnt/persist/etc/sops/identities.txt
elif [ ! -f /mnt/persist/etc/sops/identities.txt ]; then
  touch /mnt/persist/etc/sops/identities.txt
fi
chmod 600 /mnt/persist/etc/sops/identities.txt

# The running system reads keys from /etc, so put copies there too.
mkdir -p /mnt/etc/ssh /mnt/etc/sops
cp -a /mnt/persist/etc/ssh/ssh_host_ed25519_key* /mnt/etc/ssh/
cp -a /mnt/persist/etc/sops/identities.txt /mnt/etc/sops/

echo "--------------------------------------------------"
echo " Age public key for ${HOST} (add it to .sops.yaml):"
ssh-to-age </mnt/persist/etc/ssh/ssh_host_ed25519_key.pub
echo "--------------------------------------------------"

# 3. Install
echo "--> [3/6] Installing NixOS (this takes a while)..."
nixos-install --flake "${FLAKE}#${HOST}" --no-root-passwd

# 4. Impermanence: / (the @ subvolume) is wiped on the first boot, so keep
#    the state nixos-install already created (uid/gid map, machine id).
echo "--> [4/6] Seeding /persist with state created during install..."
for p in etc/machine-id var/lib/nixos var/lib/systemd; do
  if [ -e "/mnt/${p}" ] && [ ! -e "/mnt/persist/${p}" ]; then
    mkdir -p "/mnt/persist/$(dirname "${p}")"
    cp -a "/mnt/${p}" "/mnt/persist/${p}"
  fi
done

# 5. Put the repo where mcli expects it (~/MisguidedFramework)
echo "--> [5/6] Copying the repo into the new home directory..."
USER_NAME="${MISGUIDED_USER:-mercury}" # the den user in modules/den.nix
TARGET="/mnt/home/${USER_NAME}/MisguidedFramework"
if [ -d "${FLAKE}" ] && [ ! -e "${TARGET}" ]; then
  mkdir -p "$(dirname "${TARGET}")"
  cp -a "$(realpath "${FLAKE}")" "${TARGET}"
  # First normal user is uid 1000, group "users" is gid 100
  chown -R 1000:100 "/mnt/home/${USER_NAME}"
  echo "    Repo copied to /home/${USER_NAME}/MisguidedFramework"
else
  echo "    Skipped (flake is not a local directory, or ${TARGET} exists)."
  echo "    After first boot: git clone https://github.com/MercNetwork/MisguidedFramework ~/MisguidedFramework"
fi

echo "--> [6/6] Done."
echo "=================================================="
echo " Reboot, log in as ${USER_NAME} (default password: chloe),"
echo " then set your own hash in modules/aspects/mercury.nix."
echo "=================================================="
