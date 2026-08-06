---
description: Design and architectural decisions for the nixon workstation flake.
title: nixon architecture
---

## nixon architecture

`nixon` is a NixOS workstation configuration covering two machines that run
the same profile. Nix Flakes provide the pinned dependency graph and system
entrypoint; Home Manager owns the user-level applications, shell, desktop
preferences, and development tools.

### System boundaries

```text
flake.nix
├── hosts/nixos/          Dell XPS 13 7390 — Intel laptop
├── hosts/workstation/    AM5 desktop — Ryzen 9600X + RTX 5060 Ti
├── hosts/installer/      live ISO used to install the above
├── modules/nixos/        system services and platform policy
├── home/marcussky/       user environment and COSMIC preferences
├── nix/packages/         local package definitions
└── nix/tools.nix         project-local tool registry
```

Host-specific facts stay under `hosts/`; reusable operating-system policy
belongs under `modules/nixos/`; user choices belong under `home/marcussky/`.

### One profile, two machines

`mkHost` in `flake.nix` composes the shared module list; a host directory
supplies only what is genuinely machine-specific — disks, encryption,
identity — plus one platform module from `modules/nixos/hardware/`.

The split inside `modules/nixos/hardware/` is the load-bearing part.
`common.nix` holds tuning that is true of any machine this configuration runs
on: zram ahead of encrypted disk swap, the NVMe scheduler, `noatime`, BBR.
Anything that depends on the CPU vendor, the GPU, the amount of RAM, or
whether the machine has a battery lives in `xps13.nix` or `workstation.nix`.
Build parallelism sits there too: how many jobs a machine can absorb is a
hardware fact, not Nix policy, so `nix-settings.nix` keeps only the policy.

The two machines diverge more than their shared profile suggests, and the
reasons are worth stating:

- **Kernel.** The laptop runs zen for its 1000 Hz tick and full preemption,
  which is what makes an Ice Lake chip under thermal pressure feel responsive.
  The workstation runs the mainline kernel: its NVIDIA module is out-of-tree
  and is the most likely thing to break a `nix flake update`, and zen tracks
  new mainline releases within days.
- **NVIDIA.** Blackwell has no proprietary kernel module, so
  `hardware.nvidia.open` is not a preference — it is the only module that
  binds an RTX 5060 Ti.
- **Idle behaviour.** The laptop suspends. The workstation must not: it is
  reached over SSH, and suspending on graphical idle would kill both the
  running job and every session attached to it.
- **Encryption.** Both roots are encrypted, but only the workstation runs an
  SSH daemon in the initrd, because only the workstation gets rebooted by
  someone who is not standing next to it.

### Disks are configuration

The workstation's disk layout is declared in
`hosts/workstation/disk-config.nix` and realised by
[disko](https://github.com/nix-community/disko). Partition table, ESP, LUKS2
container, and root filesystem are one description that both creates the disk
and describes it to the running system.

The alternative — `nixos-generate-config` plus a hand-typed `cryptsetup`
sequence — produces two artefacts that must agree and have no mechanism
forcing them to. The failure is quiet: a `boot.initrd.luks.devices` entry
naming a container that no longer exists stops the machine at boot, long
after the mistake was made. Nothing in this repository now records a disk
UUID, so nothing can record it wrongly.

Hosts installed the older way keep a generated `hardware-configuration.nix`;
`just adopt-hardware` refreshes it. Hosts using disko have no such file, and
`hardware.nix` carries only what a scan cannot infer — the modules stage 1
needs before any disk is readable.

### Installer image

`hosts/installer/` is the workstation profile plus the ISO machinery, not a
separate rescue system. `flake.nix` hoists the shared module list into
`sharedModules`, and both real hosts and the image are built from it, so the
live session has the same driver stack, desktop, and user profile the
installed machine will have.

This is a hardware decision, not a convenience. Stock installer images ship
nouveau, which cannot drive Blackwell. The observed failure is not a hang:
the kernel stays up and answers Ctrl+Alt+Del, but the greeter takes the DRM
device and the VT, fails, and leaves a black screen with no console to switch
back to. An installer that cannot render on the machine it is installing is
not an installer.

The image deliberately excludes `hosts/workstation`. Disks, bootloader, and
identity belong to the machine being installed, not to the stick doing the
installing. It also forces off Plymouth — which hides exactly the output
needed when a live image misbehaves — along with Docker and the container
toolkit, which are dead weight on read-only media.

### Why NixOS + Home Manager?

NixOS provides declarative control over boot, networking, services, hardware,
and system packages. Home Manager provides the same model for the user
profile, avoiding a second imperative package-management workflow for shell
tools and desktop applications.

The lockfile is the source of truth for external inputs. Stable nixpkgs is the
base channel; the unstable channel is used selectively where a package needs
it. Local tool integrations such as uv2nix, cargo2nix, and bun2nix remain
available for real project manifests without forcing unused scaffolding into
the workstation profile.

### Module organization

| Area | Location | Responsibility |
|---|---|---|
| Host | `hosts/<name>/` | Disks, boot, encryption, hostname, user identity |
| Platform | `modules/nixos/hardware/` | CPU, GPU, memory, and build-capacity tuning |
| System | `modules/nixos/` | Desktop, networking, Docker, shell, Nix policy |
| Desktop | `home/marcussky/cosmic.nix` | COSMIC panels, dock, workspaces, shortcuts, favorites |
| User tools | `home/marcussky/packages/` | Always-on, development, agent, and opt-in package profiles |
| Local packages | `nix/packages/` | Packages not supplied directly by nixpkgs |
| Tool registry | `nix/tools.nix` | Project-local tool package composition |

Package profiles are deliberately separate. Core and development tools are
enabled by default; Kubernetes, media, and diagnostics remain opt-in because
they add specialized or heavier dependencies.

### Desktop decisions

COSMIC is the desktop environment. Its system module enables the compositor,
greeter, audio stack, and core services; the Home Manager module describes the
user-facing panel and dock layout. Applications are pinned by desktop-file ID
in the dock, while package installation remains in the package profiles.

Ghostty is the preferred terminal, / is the terminal multiplexer, and
COSMIC Edit is the lightweight graphical scratchpad editor. Zed remains the
full development editor. These tools have distinct roles rather than being
aliases for one another.

### Quality gates

The repository uses standalone Rust [prek](https://github.com/j178/prek), not
the Nix-generated `git-hooks.nix` wrapper. `.envrc` installs the Git hooks when
direnv enters the repository. The root `.pre-commit-config.yaml` runs the same
system-pinned tools used by the development shell:

- Nix formatting and static analysis (`nixpkgs-fmt`, `statix`, `deadnix`)
- Markdown linting and formatting (`rumdl`)
- TOML validation and linting (`check-toml`, `tombi`)
- spelling (`codespell`)
- Justfile formatting and analysis (`just`, `just-lsp`)
- repository hygiene and conventional commit checks

Use `just lint` for the full suite. The flake also exposes the suite as a
quality check so CI can evaluate the same gate in a clean Nix environment.
Detailed prek rationale lives in [`tools/prek/ARCHITECTURE.md`](tools/prek/ARCHITECTURE.md).

### Design principles

- Keep system policy, host facts, and user preferences in separate layers.
- Prefer pinned, declarative packages over ad hoc global installations.
- Keep specialized stacks opt-in and the default workstation lightweight.
- Document architectural reasons in `ARCHITECTURE.md`; keep command-oriented
  instructions in `README.md`.
- Make quality checks reproducible locally and in the flake.
