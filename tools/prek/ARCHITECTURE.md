---
description: Why nixon uses prek for repository quality gates.
title: prek
---

The repository uses [prek](https://github.com/j178/prek), a Rust drop-in
replacement for `pre-commit`. It is a single binary, uses the familiar
`.pre-commit-config.yaml` format, and avoids adding a separate Python runtime
just to run Git hooks.

## Why prek?

| Alternative | Trade-off |
|---|---|
| **pre-commit (Python)** | Adds a Python hook runtime and environment management |
| **lefthook or husky** | Introduces a different configuration model and runtime |
| **No hooks** | Allows formatting, spelling, and configuration drift |

prek keeps the standard pre-commit hook ecosystem while fitting naturally into
the Nix development shell.

## How nixon uses it

- `nix develop` provides prek and all system hooks.
- `.envrc` runs `prek install` automatically on shell entry; it is idempotent.
- `.pre-commit-config.yaml` defines the repository-wide quality gates.
- `just lint` and `prek run --all-files` run the complete suite.
- `nix flake check` evaluates the same quality gate in the flake check output.

The current hooks are intentionally repository-wide: Nix formatting and linting,
Markdown linting, spelling, TOML validation, and Justfile formatting/linting.
If the repository later gains substantial language-specific toolchains, a
nested `.pre-commit-config.yaml` can scope those hooks to that subdirectory.

## Trade-offs

prek is newer and has a smaller community than pre-commit. The configuration is
portable, but this repository’s `language: system` hooks expect contributors to
work inside the Nix development environment so every executable is pinned by
Nix.
