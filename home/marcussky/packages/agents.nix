# Editors and agent tools retained in the default workstation profile.
{ pkgs, pkgs-unstable, ... }:

let
  superset-desktop = import ../../../nix/packages/superset-desktop.nix { inherit pkgs; };
in
{
  home.packages = with pkgs; [
    neovim
    zed-editor
    obsidian

    # pkgs-unstable.mistral-vibe is broken upstream; use `vibe` from shell.nix.
    # pkgs-unstable.code-cursor
    # pkgs-unstable.antigravity
    pkgs-unstable.opencode
    pkgs-unstable.claude-code
    pkgs-unstable.codex
    pkgs-unstable.pi-coding-agent
    superset-desktop
  ];
}
