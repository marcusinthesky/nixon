# COSMIC Desktop — Home Manager configuration
#
# The COSMIC system itself is enabled by the NixOS module. cosmic-manager
# owns user-level COSMIC state, panels, applets, shortcuts, and COSMIC apps.
# Stylix remains responsible for the cross-application theme foundation.
_:

{
  wayland.desktopManager.cosmic = {
    enable = true;

    # Keep the desktop reproducible without deleting settings created by
    # newer COSMIC versions until they are explicitly declared here.
    resetFiles = false;
  };

  # Keep COSMIC-native basics available while retaining Ghostty as the
  # preferred terminal configured in ghostty.nix.
  programs.cosmic-files.enable = true;
  programs.cosmic-edit.enable = true;
}
