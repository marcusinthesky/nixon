# theme.nix — single source of truth for the visual identity
#
# Every theming decision lives here. Both the NixOS-level Stylix
# module and the Home Manager COSMIC config import this file so
# nothing is duplicated.
#
# To switch look-and-feel, edit ONLY this file and run:
#   just switch
{
  # ── Colour scheme ──────────────────────────────────────────────────────
  # Name must match a YAML file under ${pkgs.base16-schemes}/share/themes/
  # Popular choices: tokyo-night-dark, catppuccin-mocha, nord,
  #   gruvbox-dark-hard, everforest, kanagawa, rose-pine
  scheme = "tokyo-night-dark";
  polarity = "dark"; # "dark" or "light"

  # ── Fonts ──────────────────────────────────────────────────────────────
  fonts = {
    monospace = {
      # Attribute path under pkgs for the package
      pkg = "nerd-fonts.caskaydia-mono";
      name = "CaskaydiaMono Nerd Font";
    };
    sansSerif = {
      pkg = "noto-fonts";
      name = "Noto Sans";
    };
    serif = {
      pkg = "noto-fonts";
      name = "Noto Serif";
    };
    emoji = {
      pkg = "noto-fonts-color-emoji";
      name = "Noto Color Emoji";
    };
    sizes = {
      terminal = 13;
      applications = 11;
      desktop = 11;
    };
  };

  # ── Cursor ─────────────────────────────────────────────────────────────
  cursor = {
    pkg = "bibata-cursors";
    name = "Bibata-Modern-Ice";
    size = 24;
  };

  # ── Opacity ────────────────────────────────────────────────────────────
  opacity = {
    terminal = 0.95;
  };

  # ── Wallpaper ──────────────────────────────────────────────────────────
  # Set to a path (e.g. ./wallpaper.png) to use a real image.
  # null = generate a solid-colour placeholder from the scheme.
  wallpaper = null;

  # Base00 hex (no #) — used for the solid-colour fallback wallpaper.
  # Keep in sync with the scheme or leave as-is (Tokyo Night bg).
  wallpaperFallbackColor = "1a1b26";
}
