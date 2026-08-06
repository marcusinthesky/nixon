---
description: Design and architectural decisions for the nixon workstation flake.
title: nixon architecture
---

# nixon architecture

`nixon` is a single-host NixOS workstation configuration. Nix Flakes provide
the pinned dependency graph and system entrypoint; Home Manager owns the
user-level applications, shell, desktop preferences, and development tools.

## System boundaries

```text
flake.nix
├── hosts/nixos/          hardware and host identity
├── modules/nixos/        system services and platform policy
├── home/marcussky/       user environment and COSMIC preferences
├── nix/packages/         local package definitions
└── nix/tools.nix         project-local tool registry
```

The flake builds one `nixosConfigurations.nixos` output for the current
machine. Host-specific facts stay under `hosts/`; reusable operating-system
policy belongs under `modules/nixos/`; user choices belong under
`home/marcussky/`.

## Why NixOS + Home Manager?

NixOS provides declarative control over boot, networking, services, hardware,
and system packages. Home Manager provides the same model for the user
profile, avoiding a second imperative package-management workflow for shell
tools and desktop applications.

The lockfile is the source of truth for external inputs. Stable nixpkgs is the
base channel; the unstable channel is used selectively where a package needs
it. Local tool integrations such as uv2nix, cargo2nix, and bun2nix remain
available for real project manifests without forcing unused scaffolding into
the workstation profile.

## Module organization

| Area | Location | Responsibility |
|---|---|---|
| Host | `hosts/nixos/` | Hardware, boot, hostname, user identity |
| System | `modules/nixos/` | Desktop, networking, Docker, shell, tuning, Nix policy |
| Desktop | `home/marcussky/cosmic.nix` | COSMIC panels, dock, workspaces, shortcuts, favorites |
| User tools | `home/marcussky/packages/` | Always-on, development, agent, and opt-in package profiles |
| Local packages | `nix/packages/` | Packages not supplied directly by nixpkgs |
| Tool registry | `nix/tools.nix` | Project-local tool package composition |

Package profiles are deliberately separate. Core and development tools are
enabled by default; Kubernetes, media, and diagnostics remain opt-in because
they add specialized or heavier dependencies.

## Desktop decisions

COSMIC is the desktop environment. Its system module enables the compositor,
greeter, audio stack, and core services; the Home Manager module describes the
user-facing panel and dock layout. Applications are pinned by desktop-file ID
in the dock, while package installation remains in the package profiles.

Ghostty is the preferred terminal, / is the terminal multiplexer, and
COSMIC Edit is the lightweight graphical scratchpad editor. Zed remains the
full development editor. These tools have distinct roles rather than being
aliases for one another.

## Quality gates

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

## Design principles

- Keep system policy, host facts, and user preferences in separate layers.
- Prefer pinned, declarative packages over ad hoc global installations.
- Keep specialized stacks opt-in and the default workstation lightweight.
- Document architectural reasons in `ARCHITECTURE.md`; keep command-oriented
  instructions in `README.md`.
- Make quality checks reproducible locally and in the flake.
