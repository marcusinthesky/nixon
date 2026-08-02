# COSMIC from nixpkgs-unstable
#
# The system tracks nixos-26.05, which ships COSMIC 1.2.0. This overlay
# replaces every COSMIC package with its nixos-unstable counterpart (1.5.0)
# while keeping the rest of the system on the stable channel.
#
# The overlay must cover the *whole* desktop: a 1.5 compositor next to a 1.2
# session or portal is a session that does not start. Hence the prefix match
# plus the explicitly named portal, which carries no `cosmic-` prefix.
# `or prev.${name}` keeps packages that exist only on the stable channel.
#
# Because home-manager runs with `useGlobalPkgs`, cosmic-manager and the
# user-level COSMIC applications inherit the same overlaid packages.
{ lib, pkgs-unstable, ... }:

{
  nixpkgs.overlays = [
    (_: prev:
      let
        cosmicPackages = builtins.filter
          (name: lib.hasPrefix "cosmic-" name || name == "xdg-desktop-portal-cosmic")
          (builtins.attrNames prev);
      in
      lib.genAttrs cosmicPackages (name: pkgs-unstable.${name} or prev.${name}))
  ];
}
