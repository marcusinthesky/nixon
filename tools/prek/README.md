---
description: prek — Rust drop-in replacement for pre-commit
---

# prek

[prek](https://github.com/j178/prek) is the repository’s Git hook runner.
It uses the standard `.pre-commit-config.yaml` format and is provided by the
Nix development shell.

## Key commands

```bash
direnv allow                 # activate the flake and install hooks
prek install                 # install hooks manually
prek run --all-files         # run every hook
just lint                    # run the same full hook suite
```

The root configuration covers Nix, Markdown, spelling, TOML, and Justfile
quality checks. There are no nested language-specific hook configurations in
this repository yet.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the rationale and trade-offs.
