# Home Manager — marcussky
#
# Entrypoint that imports all per-concern modules.
# Each module is self-contained and can be toggled by removing the import.
# Theming (colours, fonts, cursors, icons) is driven by Stylix via
# theme.nix — per-app modules only set layout / behaviour.
_:

{
  imports = [
    ./ghostty.nix
    ./starship.nix
    ./git.nix
    ./shell.nix
    ./direnv.nix
    ./vscode.nix
    ./packages
    ./cosmic.nix
  ];

  # COSMIC creates these GTK CSS symlinks itself; do not let Stylix's
  # Home Manager target try to replace them.
  stylix.targets.gtk.enable = false;

  home.stateVersion = "25.11";
}
