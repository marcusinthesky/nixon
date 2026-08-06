# nixon — common tasks
#
# Usage: just <recipe>
# Requires: https://github.com/casey/just

cosmic_substituter := "https://cosmic.cachix.org/"
cosmic_public_key := "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="

# Which nixosConfiguration to act on. Defaults to this machine's hostname, so
# `just switch` always means "this box". Override for cross-host work:
#   just host=workstation build
host := `hostname`

# Default recipe — show available commands
default:
    @just --list

# ── System ─────────────────────────────────────────────────────────────

# Build and switch to the new configuration
switch:
    sudo nixos-rebuild switch --flake .#{{ host }} --use-substitutes --no-write-lock-file --option extra-substituters '{{ cosmic_substituter }}' --option extra-trusted-public-keys '{{ cosmic_public_key }}'

# Build without switching (dry run)
build:
    nixos-rebuild build --flake .#{{ host }} --no-write-lock-file

# Test the configuration (activate without adding to bootloader)
test:
    sudo nixos-rebuild test --flake .#{{ host }} --use-substitutes --no-write-lock-file

# Build {{ host }} on another machine over SSH, then activate it here.
# `builder` is an ssh destination (marcussky@workstation). nixos-rebuild runs
# under sudo, so the SSH client is root and needs a key root can actually read
# — hence the explicit identity rather than your agent.
switch-on builder key="/root/.ssh/id_ed25519":
    sudo NIX_SSHOPTS="-i {{ key }}" nixos-rebuild switch --flake .#{{ host }} --build-host {{ builder }} --use-substitutes --no-write-lock-file

# ── Installation ───────────────────────────────────────────────────────

# Build the COSMIC + Calamares installer ISO (symlinked as ./result-iso)
iso:
    nix build .#installer-iso --out-link result-iso --no-write-lock-file
    @echo "ISO: $(readlink -f result-iso)/iso/$(ls result-iso/iso)"

# Write the installer ISO to a USB stick (interactive device picker)
flash: iso
    sudo $(command -v popsicle) --unmount --check "$(readlink -f result-iso)/iso/"*.iso

# Same, in Popsicle's GTK interface
flash-gui: iso
    sudo -E $(command -v popsicle-gtk) "$(readlink -f result-iso)/iso/"*.iso

# Import this machine's hardware scan into hosts/{{ host }}/ (run once, post-install)
adopt-hardware:
    bash tools/adopt-hardware.sh {{ host }}

# ── Quality Gates ──────────────────────────────────────────────────────

# Run all prek hooks on every file
lint:
    nix develop -c prek run --all-files

# Install prek's Git hooks for this repository
install-hooks:
    nix develop -c prek install

# Format all Nix files
fmt:
    nix fmt

# Run statix linter on all Nix files
statix:
    nix develop -c statix check .

# Detect unused Nix bindings
deadnix:
    nix develop -c deadnix .

# Scan the system closure for known CVEs (vulnix)
vulnix:
    nix develop -c vulnix --system

# Run Nix evaluation and the prek quality check
check:
    nix flake check

# ── Flake Management ──────────────────────────────────────────────────

# Update the primary stable channel only. Use `just update-all` deliberately.
update:
    nix flake lock --update-input nixpkgs

# Update a single input
update-input input:
    nix flake lock --update-input {{ input }}

# Update every input, including unstable and project-local tool integrations.
update-all:
    nix flake update

# Show the flake outputs
show:
    nix flake show

# Enter the development shell (hooks install automatically)
dev:
    nix develop

# ── Maintenance ────────────────────────────────────────────────────────

# Garbage collect old generations
gc:
    sudo nix-collect-garbage -d

# Run store deduplication manually when disk usage warrants the extra work.
optimise:
    sudo nix-store --optimise

# List system generations
generations:
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Diff against the running system
diff:
    nix store diff-closures /run/current-system $(nixos-rebuild build --flake .#{{ host }} --print-out-paths 2>/dev/null)
