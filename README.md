# nixon

[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fmarcusinthesky%2Fnixon.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fmarcusinthesky%2Fnixon?ref=badge_shield)

![cover](cover.webp)

Declarative NixOS workstation configuration managed with [Nix Flakes](https://wiki.nixos.org/wiki/Flakes) and [Home Manager](https://github.com/nix-community/home-manager).

## Structure

```text
nixon/
├── flake.nix                          # Entrypoint: inputs + nixosConfigurations
├── justfile                           # Common tasks (just switch, just update, etc.)
├── hosts/
│   └── nixos/                         # Per-host config (add more hosts here)
│       ├── default.nix                # Boot, LUKS, hostname, user, stateVersion
│       └── hardware-configuration.nix # Auto-generated hardware scan
├── modules/
│   └── nixos/                         # Shared NixOS system modules
│       ├── desktop.nix                # COSMIC, greeter, audio (PipeWire), printing
│       ├── docker.nix                 # Docker daemon + weekly auto-prune
│       ├── hardware-tuning.nix        # Kernel, zram, thermald, Intel VA-API
│       ├── networking.nix             # OpenSSH, Tailscale, firewall
│       ├── nix-settings.nix           # Flakes, store optimisation, GC
│       └── shell.nix                  # System zsh (oh-my-zsh, plugins, nix-ld)
├── nix/
│   ├── packages/                       # Custom packages outside nixpkgs
│   └── tools.nix                         # Explicit installed tool registry
├── tools/
│   ├── prek/                            # Hook architecture and usage
│   ├── python/                          # uv/uv2nix workspace
│   ├── rust/                            # Cargo/cargo2nix workspace
│   └── bun/                             # Bun/bun2nix workspace
└── home/
    └── marcussky/                     # Per-user Home Manager config
        ├── default.nix                # Imports all sub-modules
        ├── direnv.nix                 # Auto env loading + nix-direnv
        ├── ghostty.nix                # Ghostty terminal config
        ├── cosmic.nix                 # Declarative COSMIC user configuration
        ├── git.nix                    # Git identity, delta, aliases, gh CLI
        ├── packages/                  # Core, development, agents, and opt-in profiles
        │   ├── default.nix
        │   ├── core.nix
        │   ├── development.nix
        │   ├── agents.nix
        │   ├── kubernetes.nix
        │   ├── media.nix
        │   └── diagnostics.nix
        ├── shell.nix                  # User zsh aliases, session vars
        ├── starship.nix               # Shell prompt (k8s, git, nix-shell)
        └── vscode.nix                 # VS Code + declarative extensions
```

## Quick Start

### Prerequisites

- NixOS with flakes enabled
- [just](https://github.com/casey/just) (optional, for convenience)
- `direnv` and `prek` (both provided/configured by the development shell)

### First-time setup

```bash
# Clone the repo
git clone <your-repo-url> ~/Git/nixon
cd ~/Git/nixon

# Build and switch (replaces /etc/nixos/configuration.nix)
sudo nixos-rebuild switch --flake .#nixos
# — or with just —
just switch
```

### Daily usage

```bash
# direnv runs `prek install` automatically when entering the repository
just switch       # Rebuild and activate
just update       # Update flake inputs (nixpkgs, home-manager)
just build        # Build without activating (dry run)
just test         # Activate without adding to bootloader
just lint          # Run Nix, Markdown, spelling, TOML, and Justfile hooks
just check        # Validate the flake and prek quality check
just fmt          # Format all Nix files
just gc           # Garbage collect old generations
```

## Adding a new host

1. Create `hosts/<hostname>/default.nix` with machine-specific config
2. Copy `hardware-configuration.nix` into the same directory
3. Add a new `nixosConfigurations.<hostname>` block in `flake.nix`
4. Run `sudo nixos-rebuild switch --flake .#<hostname>`

## Adding a new user

1. Create `home/<username>/default.nix` importing the modules you want
2. Add a `home-manager.users.<username>` entry in `flake.nix`
3. Add the user account in the host's `default.nix`

## Design Principles

- **Home Manager first** — user tools, dotfiles, and shell config are managed per-user
- **One file per concern** — each `.nix` file owns exactly one domain
- **DRY via `specialArgs`** — username/description passed once, reused everywhere
- **Extensible** — add hosts, users, or modules without touching existing files
- **Pinned inputs** — `flake.lock` ensures reproducible builds
- **Fast default switch** — specialist infrastructure, media, and diagnostics
  profiles are available under `home/marcussky/packages/` but are not imported
  by default
- **Tool-local toolchains** — use `uv2nix`, `cargo2nix`, or `bun2nix` only for
  tools that have the corresponding lockfile; see [`nix/README.md`](nix/README.md)
