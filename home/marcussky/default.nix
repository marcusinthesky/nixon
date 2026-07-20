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
    ./btop.nix
    ./vscode.nix
    ./packages
    ./cosmic.nix
    ./zed.nix
  ];

  home.stateVersion = "25.11";
}
