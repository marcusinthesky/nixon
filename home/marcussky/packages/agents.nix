# Editors and agent CLIs retained on every host.
#
# All from the locked stable nixpkgs, so they arrive from cache.nixos.org
# with the rest of the system. claude-code also self-updates into
# ~/.local/bin, which shell.nix keeps ahead of this copy on PATH.
{ pkgs, ... }:

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
    codex
    pi-coding-agent
    herdr
  ];
}
