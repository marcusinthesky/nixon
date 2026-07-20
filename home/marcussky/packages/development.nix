# Language toolchains, formatters, and language servers.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Structured configuration
    yaml-language-server
    tombi

    # Go
    go
    gopls
    delve

    # Rust
    cargo
    rustc
    clippy
    rustfmt

    # Python
    uv
    ty
    ruff

    # JavaScript / TypeScript
    bun
    deno
    typescript-language-server

    # Lean
    elan

    # Nix
    nixfmt
    nixpkgs-fmt
    statix
    deadnix
    nixd
    prek
    convco
    rumdl
    codespell

    # Typst, Markdown, Quarto, and LaTeX
    typst
    tinymist
    # Quarto pulls a large R/SDL runtime. Enable it deliberately when needed
    # for publishing projects; Typst/Tectonic remain available by default.
    # quarto
    marksman
    tectonic

    # Task runner
    just
    just-lsp

    # Native build
    git-cliff
    gnumake
    gcc
    binutils
  ];
}
