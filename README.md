# nixify

[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fmarcusinthesky%2Fnixify.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fmarcusinthesky%2Fnixify?ref=badge_shield)

![cover](cover.webp)

Declarative NixOS workstation configuration managed with [Nix Flakes](https://wiki.nixos.org/wiki/Flakes) and [Home Manager](https://github.com/nix-community/home-manager).

## Structure

```
nixify/
├── flake.nix                          # Entrypoint: inputs + nixosConfigurations
├── justfile                           # Common tasks (just switch, just update, etc.)
├── hosts/
│   └── nixos/                         # Per-host config (add more hosts here)
│       ├── default.nix                # Boot, LUKS, hostname, user, stateVersion
│       └── hardware-configuration.nix # Auto-generated hardware scan
├── modules/
│   └── nixos/                         # Shared NixOS system modules
│       ├── desktop.nix                # GNOME, GDM, audio (PipeWire), printing
│       ├── docker.nix                 # Docker daemon + weekly auto-prune
│       ├── fonts.nix                  # Nerd Fonts (JetBrainsMono, FiraCode)
│       ├── networking.nix             # OpenSSH, Tailscale, firewall
│       ├── nix-settings.nix           # Flakes, store optimisation, GC
│       └── shell.nix                  # System zsh (oh-my-zsh, plugins, nix-ld)
└── home/
    └── marcussky/                     # Per-user Home Manager config
        ├── default.nix                # Imports all sub-modules
        ├── btop.nix                   # Terminal system monitor
        ├── direnv.nix                 # Auto env loading + nix-direnv
        ├── ghostty.nix                # Ghostty terminal config
        ├── git.nix                    # Git identity, delta, aliases, gh CLI
        ├── packages.nix               # CLI tools, k8s, languages, utilities
        ├── shell.nix                  # User zsh aliases, session vars
        ├── starship.nix               # Shell prompt (k8s, git, nix-shell)
        └── vscode.nix                 # VS Code + declarative extensions
```

## Quick Start

### Prerequisites

- NixOS with flakes enabled
- [just](https://github.com/casey/just) (optional, for convenience)

### First-time setup

```bash
# Clone the repo
git clone <your-repo-url> ~/Git/nixify
cd ~/Git/nixify

# Build and switch (replaces /etc/nixos/configuration.nix)
sudo nixos-rebuild switch --flake .#nixos
# — or with just —
just switch
```

### Daily usage

```bash
just switch       # Rebuild and activate
just update       # Update flake inputs (nixpkgs, home-manager)
just build        # Build without activating (dry run)
just test         # Activate without adding to bootloader
just check        # Validate the flake
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
