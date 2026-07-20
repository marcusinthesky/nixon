# nixify — common tasks
#
# Usage: just <recipe>
# Requires: https://github.com/casey/just

cosmic_substituter := "https://cosmic.cachix.org/"
cosmic_public_key := "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="

# Default recipe — show available commands
default:
    @just --list

# ── System ─────────────────────────────────────────────────────────────

# Build and switch to the new configuration
switch:
    sudo nixos-rebuild switch --flake .#nixos --use-substitutes --no-write-lock-file --option extra-substituters '{{cosmic_substituter}}' --option extra-trusted-public-keys '{{cosmic_public_key}}'

# Build without switching (dry run)
build:
    nixos-rebuild build --flake .#nixos --no-write-lock-file

# Test the configuration (activate without adding to bootloader)
test:
    sudo nixos-rebuild test --flake .#nixos --use-substitutes --no-write-lock-file

# ── Quality Gates ──────────────────────────────────────────────────────

# Run ALL pre-commit hooks on every file
lint:
    nix develop -c pre-commit run --all-files

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

# Run nix flake check (sandboxed — used in CI)
check:
    nix flake check

# ── Flake Management ──────────────────────────────────────────────────

# Update the primary stable channel only. Use `just update-all` deliberately.
update:
    nix flake lock --update-input nixpkgs

# Update a single input
update-input input:
    nix flake lock --update-input {{input}}

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
    nix store diff-closures /run/current-system $(nixos-rebuild build --flake .#nixos --print-out-paths 2>/dev/null)
