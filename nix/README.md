# Package and toolchain architecture

This repository has two deliberately separate concerns:

1. The workstation closure: NixOS modules and Home Manager packages in
   `modules/` and `home/`. These should prefer packages already present in the
   locked nixpkgs inputs and available from configured substituters.
2. Tool closures: application or development tools with their own dependency
   manifests and lockfiles. These belong under `tools/` and should expose
   tool-specific `packages`, `devShells`, and checks.

## Selection order

For a tool used globally on the workstation:

1. Use the stable locked `nixpkgs` package.
2. Use `nixpkgs-unstable` only when the stable package is missing or unusable;
   keep that exception explicit in `home/marcussky/packages/`.
3. Do not add a custom derivation merely to install an upstream binary unless
   it has a reproducible source, a security review, and a cache/build policy.
   Such derivations belong in `nix/packages/`, not in a Home Manager module.

For dependencies belonging to a real tool:

- Python: use `uv2nix` from the project's `pyproject.toml` and `uv.lock`.
- Rust: use `cargo2nix` from the project's `Cargo.toml` and `Cargo.lock`.
- Bun: use `bun2nix` from the project's Bun lockfile.

These frameworks remain pinned in the workstation flake so project tool
closures can be added without changing the lock policy. They should still be
used only by a corresponding tool under `tools/`, rather than being evaluated
as part of the default workstation package set.

## Cache policy

The default system configuration must remain usable with binary substitutes.
Project-local source builds are opt-in through that project's `nix develop` or
package output. A tool that is not in nixpkgs and has no trusted substitute is
not promoted into the default workstation closure.

This is especially relevant to experimental desktop applications such as
Rhyolite: keep them outside the system closure until they have a pinned,
maintained package or trusted binary cache.
