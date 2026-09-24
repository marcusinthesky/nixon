# Editors and agent CLIs retained on every host.
#
# All except Codex come from the locked stable nixpkgs, so they arrive from
# cache.nixos.org with the rest of the system. Codex follows its own locked
# nixpkgs-unstable input because it releases frequently. claude-code also
# self-updates into ~/.local/bin, which shell.nix keeps ahead of this copy on
# PATH.
{ pkgs, pkgsUnstable, ... }:

let
  herdr = import ../../../nix/packages/herdr.nix { inherit pkgs; };
in
{
  home.packages = with pkgs; [
    neovim
    zed-editor

    # mistral-vibe is broken upstream; use `vibe` from shell.nix.
    opencode
    claude-code
    pkgsUnstable.codex
    pi-coding-agent
    herdr
  ];
}
