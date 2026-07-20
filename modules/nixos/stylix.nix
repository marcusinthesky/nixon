# Stylix — Unified theming for NixOS + Home Manager
#
# All visual choices are imported from /theme.nix (the single source of
# truth). This module simply wires them into Stylix options.
#
# To change the look-and-feel, edit theme.nix — not this file.
{ pkgs, lib, ... }:

let
  theme = import ../../theme.nix;

  # Resolve a dotted attribute path like "nerd-fonts.caskaydia-mono"
  # into an actual package from pkgs.
  resolvePkg = path:
    lib.attrByPath (lib.splitString "." path) (throw "package ${path} not found") pkgs;

  wallpaper =
    if theme.wallpaper != null
    then theme.wallpaper
    else
      pkgs.runCommand "wallpaper.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
        magick -size 3840x2160 canvas:#${theme.wallpaperFallbackColor} $out
      '';
in
{
  stylix = {
    enable = true;

    # ── Colour scheme ──────────────────────────────────────────────────
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${theme.scheme}.yaml";
    inherit (theme) polarity;

    # ── Wallpaper ──────────────────────────────────────────────────────
    image = wallpaper;

    # ── Fonts ──────────────────────────────────────────────────────────
    fonts = {
      monospace = {
        package = resolvePkg theme.fonts.monospace.pkg;
        inherit (theme.fonts.monospace) name;
      };
      sansSerif = {
        package = resolvePkg theme.fonts.sansSerif.pkg;
        inherit (theme.fonts.sansSerif) name;
      };
      serif = {
        package = resolvePkg theme.fonts.serif.pkg;
        inherit (theme.fonts.serif) name;
      };
      emoji = {
        package = resolvePkg theme.fonts.emoji.pkg;
        inherit (theme.fonts.emoji) name;
      };
      inherit (theme.fonts) sizes;
    };

    # ── Cursor ─────────────────────────────────────────────────────────
    cursor = {
      package = resolvePkg theme.cursor.pkg;
      inherit (theme.cursor) name;
      inherit (theme.cursor) size;
    };

    # ── Opacity ────────────────────────────────────────────────────────
    inherit (theme) opacity;

    # ── Qt ─────────────────────────────────────────────────────────────
    # COSMIC uses its own Iced/RON theme and settings system; keep Stylix's
    # Qt target disabled and let cosmic-manager handle COSMIC user state.
    targets.qt.enable = false;
  };
}
