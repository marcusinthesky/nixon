#!/usr/bin/env bash
# install.sh — install a nixon host onto this machine from the live ISO.
#
# Usage, from the live session:
#   sudo /etc/nixon/install.sh [host] [disk]
#
# Defaults to the `workstation` host on /dev/nvme0n1.
#
# Partitioning, encryption, formatting, and mounting all come from disko, so
# the layout is whatever hosts/<host>/disk-config.nix declares — not a
# sequence of commands that has to match it by hand.
set -euo pipefail

HOST="${1:-workstation}"
TARGET_DISK="${2:-/dev/nvme0n1}"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; NC=$'\033[0m'

info() { echo "${CYAN}[INFO]${NC}  $*"; }
warn() { echo "${YELLOW}[WARN]${NC}  $*"; }
ok() { echo "${GREEN}[ OK ]${NC}  $*"; }
fatal() {
  echo "${RED}[FAIL]${NC}  $*" >&2
  exit 1
}

echo
echo "${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo "${BOLD}║               nixon NixOS installer                  ║${NC}"
echo "${BOLD}║   COSMIC · LUKS2 · NVIDIA open · zsh + starship      ║${NC}"
echo "${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo

# ── Locate the flake ────────────────────────────────────────────────────────
# 1. a checkout, if we were run from one
# 2. the copy bundled on the ISO
BUNDLED_FLAKE="/etc/nixon/flake"

if [ -f "flake.nix" ]; then
  FLAKE_DIR="$(pwd)"
  SOURCE="local checkout ($FLAKE_DIR)"
elif [ -f "${BUNDLED_FLAKE}/flake.nix" ]; then
  # The bundle lives in the read-only Nix store. Nix needs a writable path to
  # evaluate a `path:` flake, so take a copy.
  FLAKE_DIR="$(mktemp -d)/nixon"
  cp -rL "$BUNDLED_FLAKE" "$FLAKE_DIR"
  chmod -R u+w "$FLAKE_DIR"
  SOURCE="ISO bundle (copied to $FLAKE_DIR)"
else
  fatal "No flake.nix found. Run from a nixon checkout, or use the nixon ISO."
fi

FLAKE_REF="path:${FLAKE_DIR}#${HOST}"

# ── Preflight ───────────────────────────────────────────────────────────────
[ "$(id -u)" -eq 0 ] || fatal "Run this with sudo."
[ -b "$TARGET_DISK" ] || fatal "No block device at $TARGET_DISK — check lsblk."
[ -d "${FLAKE_DIR}/hosts/${HOST}" ] || fatal "No such host '${HOST}' in ${FLAKE_DIR}/hosts."
[ -d /sys/firmware/efi ] || fatal "Not booted in UEFI mode. This layout is GPT + systemd-boot."

info "Flake source: $SOURCE"
info "Host:         $HOST"
echo

lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS "$TARGET_DISK"
echo

DISK_SIZE_H="$(lsblk -bdno SIZE "$TARGET_DISK" | head -n1 | numfmt --to=iec)"

echo "${BOLD}Target disk:${NC}  $TARGET_DISK ($DISK_SIZE_H)"
echo "${BOLD}Layout:${NC}       GPT → 1 GiB ESP + LUKS2 → ext4 root"
echo
echo "${RED}${BOLD}⚠  This ERASES EVERYTHING on $TARGET_DISK.${NC}"
echo
read -rp "Type YES (all caps) to proceed: " confirm
[ "$confirm" = "YES" ] || {
  echo "Aborted."
  exit 0
}
echo

# ── 1/3 disko ───────────────────────────────────────────────────────────────
echo "${BOLD}── 1/3  disko: partition, encrypt, format, mount ──${NC}"
echo
info "You will be asked to set the disk encryption passphrase."
info "It is required at every boot — do not lose it."
echo

# Build the standalone script rather than `nix run`-ing the disko module:
# it sidesteps the sandbox restrictions that bite inside a live session.
DISKO_ATTR="path:${FLAKE_DIR}#nixosConfigurations.${HOST}.config.system.build.diskoScript"
DISKO_SCRIPT="$(nix build --no-link --print-out-paths --extra-experimental-features 'nix-command flakes' "$DISKO_ATTR")" ||
  fatal "Could not build the disko script — see the evaluation errors above."

"$DISKO_SCRIPT" --mode destroy,format,mount || fatal "disko failed; see above."

mountpoint -q /mnt || fatal "/mnt is not mounted after disko."
mountpoint -q /mnt/boot || fatal "/mnt/boot is not mounted after disko."
ok "Disk partitioned, encrypted, formatted, and mounted."
echo

# ── 2/3 nixos-install ───────────────────────────────────────────────────────
echo "${BOLD}── 2/3  nixos-install ──${NC}"
echo
info "Installing $FLAKE_REF. Expect 10-30 minutes on a first run."
echo

nixos-install --flake "$FLAKE_REF" --no-root-password || fatal "nixos-install failed."
ok "System installed."
echo

# ── 3/3 login password ──────────────────────────────────────────────────────
# The host modules declare the user but never a password, and mutableUsers
# leaves credentials to the running system. Without this the machine boots to
# a greeter nobody can get past.
echo "${BOLD}── 3/3  set the login password ──${NC}"
echo

USERNAME="$(nixos-enter --root /mnt -c \
  "awk -F: '\$3 >= 1000 && \$3 < 65534 { print \$1; exit }' /etc/passwd" 2>/dev/null | tr -d '\r\n')"

if [ -z "$USERNAME" ]; then
  warn "Could not determine the login user. Set one manually before rebooting:"
  warn "  nixos-enter --root /mnt -c 'passwd <username>'"
else
  info "Setting the password for '$USERNAME' on the installed system."
  nixos-enter --root /mnt -c "passwd $USERNAME"
  ok "Password set."
fi

echo
echo "${GREEN}${BOLD}Installation complete.${NC}"
echo
echo "  1. Remove the USB stick"
echo "  2. reboot"
echo "  3. Enter the LUKS passphrase at the prompt"
echo "  4. Log in as ${USERNAME:-<user>}"
echo "  5. sudo tailscale up          # SSH is tailnet-only"
echo
read -rp "Reboot now? [y/N] " answer
case "$answer" in
  [Yy]*) reboot ;;
  *) info "When ready: reboot" ;;
esac
