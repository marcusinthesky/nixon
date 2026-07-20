# Tool workspaces

These directories contain tool-local CLI workspaces whose outputs are
installed through the root NixOS/Home Manager switch.

- `python/` — `pyproject.toml` and `uv.lock`, integrated with `uv2nix`.
- `rust/` — `Cargo.toml` and `Cargo.lock`, integrated with `cargo2nix`.
- `bun/` — `package.json` and `bun.lock`, integrated with `bun2nix`.

The root `flake.lock` pins the Nix frameworks and nixpkgs. Each workspace
lockfile pins its language ecosystem dependencies. Do not add a dependency to
one of these workspaces unless it is intended to be installed on the system.

Each tool keeps its small Nix adapter beside its manifest. The explicit
`nix/tools.nix` registry imports only completed adapters. Existing nixpkgs
packages remain the preferred implementation for globally installed tools.
