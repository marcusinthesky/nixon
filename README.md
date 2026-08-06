# nixon

[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fmarcusinthesky%2Fnixon.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fmarcusinthesky%2Fnixon?ref=badge_shield)

![cover](cover.webp)

Declarative NixOS workstation configuration managed with [Nix Flakes](https://wiki.nixos.org/wiki/Flakes) and [Home Manager](https://github.com/nix-community/home-manager).

## Structure

```text
nixon/
├── flake.nix                          # Entrypoint: inputs + nixosConfigurations
├── justfile                           # Common tasks (just switch, just iso, etc.)
├── hosts/
│   ├── nixos/                         # Dell XPS 13 7390 — Intel laptop
│   │   ├── default.nix                # Boot, LUKS, hostname, user, stateVersion
│   │   └── hardware-configuration.nix # Auto-generated hardware scan
│   ├── workstation/                   # AM5 desktop — Ryzen 9600X + RTX 5060 Ti
│   │   ├── default.nix                # Boot, remote LUKS unlock, identity
│   │   ├── disk-config.nix            # Declarative disk layout (disko)
│   │   └── hardware.nix               # Stage-1 modules; disks live in disko
│   └── installer/                     # Live ISO: the workstation, on a stick
├── modules/
│   └── nixos/                         # Shared NixOS system modules
│       ├── desktop.nix                # COSMIC, greeter, audio (PipeWire), printing
│       ├── docker.nix                 # Docker daemon + weekly auto-prune
│       ├── hardware/                  # Per-platform tuning
│       │   ├── common.nix             # zram, sysctl, storage, journal
│       │   ├── workstation.nix        # AMD pstate, NVIDIA open, no-suspend
│       │   └── xps13.nix              # zen kernel, thermald, Intel VA-API
│       ├── networking.nix             # OpenSSH, Tailscale, firewall
│       ├── nix-settings.nix           # Flakes, substituters, GC
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

### Hosts

Every system recipe acts on `host`, which defaults to the current machine's
hostname. Pass it explicitly to work on the other machine:

```bash
just switch                                    # this machine
just host=workstation build                    # build the workstation from the laptop
just switch-on marcussky@workstation           # build this host *on* the workstation
```

`switch-on` is the reason to keep the workstation on the tailnet: it hands the
build to the 9600X and only copies the result back, which turns a laptop
`nixos-rebuild` from minutes into seconds.

| Host | Machine | Notes |
|---|---|---|
| `nixos` | Dell XPS 13 7390 | Intel Ice Lake, zen kernel, thermald |
| `workstation` | Ryzen 5 9600X + RTX 5060 Ti | NVIDIA open driver, never suspends |

## Installing on a new machine

The live ISO is not a generic rescue image with extras added — it is the
workstation profile itself, booted from a stick. Same NVIDIA driver, same
COSMIC desktop, same Home Manager profile, plus this flake bundled at
`/etc/nixon` and an installer script.

That matters on NVIDIA hardware. Stock installer images ship nouveau, which
cannot drive Blackwell (GB206): the kernel stays up, but the greeter takes the
DRM device, fails, and leaves a black screen with no console to switch back
to. Shipping the real driver removes the whole class of problem.

### 1. Build and write the ISO

On an existing machine:

```bash
just iso     # builds ./result-iso (expect ~7 GB)
just flash   # writes it to a USB stick, then verifies the copy
```

`just flash` runs Popsicle's CLI, which lists the attached USB devices and asks
which to write. `just flash-gui` opens the same tool's GTK interface instead.
It prints nothing until it finishes — with `--check` it makes two full passes,
write then verify, so a long silence is expected.

### 2. Install

In the UEFI first: **enable EXPO** (DDR5 runs at JEDEC 4800 otherwise), enable
Resizable BAR and Above 4G Decoding, and turn Secure Boot off — the NVIDIA
kernel module is out-of-tree and unsigned. Then F11 for the boot menu.

The live session autologins to COSMIC. Run the installer from the desktop
launcher, or:

```bash
sudo /etc/nixon/install.sh                       # defaults: workstation, /dev/nvme0n1
sudo /etc/nixon/install.sh workstation /dev/nvme1n1
```

It asks you to type `YES`, then hands partitioning to
[disko](https://github.com/nix-community/disko), which realises
`hosts/workstation/disk-config.nix` — GPT, 1 GiB ESP, LUKS2, ext4 root. There
is no manual `gdisk`/`cryptsetup` sequence to keep in step with the config,
and no generated UUID to copy into the host module afterwards.

Then `nixos-install`, then a prompt for the login password, then reboot. Two
different passwords are involved — the LUKS passphrase during partitioning and
the account password at the end — and the script asks for them at clearly
separate steps.

Because the flake is bundled on the ISO, the install needs no access to
GitHub. It does still need a network connection to download packages.

### 3. Enable remote unlock

The workstation's root filesystem is encrypted, so a remote reboot otherwise
stops at a passphrase prompt with no way in. Add the laptop's public key to
`sshKeys` in `hosts/workstation/default.nix`, generate a dedicated initrd host
key on the workstation, and switch:

```bash
sudo mkdir -p /etc/secrets/initrd
sudo ssh-keygen -t ed25519 -N "" -f /etc/secrets/initrd/ssh_host_ed25519_key
just host=workstation switch
```

After that, a reboot is recoverable from anywhere on the LAN:

```bash
ssh -p 2222 root@workstation
systemd-tty-ask-password-agent    # type the LUKS passphrase
```

Remote unlock stays switched off while `sshKeys` is empty, so the flake still
evaluates on a machine that has not been keyed yet.

## Adding a new host

1. Create `hosts/<hostname>/default.nix` with machine-specific config
2. Declare the disks in `hosts/<hostname>/disk-config.nix` (disko), or copy in
   a generated `hardware-configuration.nix` and run `just adopt-hardware`
3. Import a platform module from `modules/nixos/hardware/`, or add one
4. Add `<hostname> = mkHost ./hosts/<hostname>;` in `flake.nix`
5. Run `just host=<hostname> switch`

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
