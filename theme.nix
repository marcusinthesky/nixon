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

  # ── Case lighting ──────────────────────────────────────────────────────
  # Hex (no #) driven onto every RGB zone OpenRGB can reach, on the hosts
  # that have any. Only the workstation does — see
  # modules/nixos/hardware/workstation.nix.
  #
  # This is deliberately more saturated and further from yellow than a
  # "sunset orange" swatch looks on screen. Diffused LEDs run hot on the
  # green channel, so a picker-accurate ff8c42 lands somewhere near amber
  # in an actual fan hub. Raise the middle byte toward 6a if it reads too
  # red on yours, lower it toward 30 if it reads yellow.
  rgb = "ff4a00";

  # ── Wallpaper ──────────────────────────────────────────────────────────
  # Set to a path (e.g. ./wallpaper.png) to use a real image.
  # null = generate a solid-colour placeholder from the scheme.
  wallpaper = null;

  # Base00 hex (no #) — used for the solid-colour fallback wallpaper.
  # Keep in sync with the scheme or leave as-is (Tokyo Night bg).
  wallpaperFallbackColor = "1a1b26";
}
