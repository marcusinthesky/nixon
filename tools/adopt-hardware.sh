#!/usr/bin/env bash
#
# Import the running machine's hardware scan into hosts/<host>/.
#
#   just host=nixos adopt-hardware
#
# Only for hosts that carry a generated hardware-configuration.nix. The
# workstation does not: its disks are declared in hosts/workstation/
# disk-config.nix and realised by disko, so there is nothing to scan and
# nothing that can drift out of sync.
set -euo pipefail

host="${1:?usage: adopt-hardware.sh <host>}"

hw="hosts/${host}/hardware-configuration.nix"
module="hosts/${host}/default.nix"

if [ ! -f "$module" ]; then
  echo "error: no such host '${host}' (expected ${module})" >&2
  exit 1
fi

if [ ! -f "$hw" ]; then
  echo "error: ${host} has no hardware-configuration.nix." >&2
  echo "       Hosts using disko declare their disks instead — see" >&2
  echo "       hosts/${host}/disk-config.nix." >&2
  exit 1
fi

echo ":: scanning hardware into ${hw}"
# The redirect is deliberately unprivileged: only the scan needs root, and the
# file it lands in belongs to whoever owns the checkout.
# shellcheck disable=SC2024
sudo nixos-generate-config --show-hardware-config >"$hw"

echo ":: done — review the diff, then \`just host=${host} switch\`"
