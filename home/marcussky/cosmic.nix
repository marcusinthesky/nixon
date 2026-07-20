# COSMIC Desktop — Home Manager configuration
#
# The COSMIC system itself is enabled by the NixOS module. cosmic-manager
# owns user-level COSMIC state, panels, applets, shortcuts, and COSMIC apps.
# Stylix remains responsible for the cross-application theme foundation.
{ cosmicLib, ... }:

{
  wayland.desktopManager.cosmic = {
    enable = true;

    # Keep the desktop reproducible without deleting settings created by
    # newer COSMIC versions until they are explicitly declared here.
    resetFiles = false;
  };

  # Keep the top panel as a thin system/status bar and put the application
  # launcher/task list in a separate bottom dock.
  wayland.desktopManager.cosmic.panels = [
    {
      name = "Panel";
      anchor = cosmicLib.cosmic.mkRON "enum" "Top";
      size = cosmicLib.cosmic.mkRON "enum" "M";
      expand_to_edges = true;
      anchor_gap = false;
      margin = 0;

      plugins_center = cosmicLib.cosmic.mkRON "optional" [
        "com.system76.CosmicAppletTime"
      ];

      plugins_wings = cosmicLib.cosmic.mkRON "optional" (
        cosmicLib.cosmic.mkRON "tuple" [
          [
            "com.system76.CosmicPanelWorkspacesButton"
          ]
          [
            "com.system76.CosmicAppletInputSources"
            "com.system76.CosmicAppletStatusArea"
            "com.system76.CosmicAppletNetwork"
            "com.system76.CosmicAppletAudio"
            "com.system76.CosmicAppletBattery"
            "com.system76.CosmicAppletPower"
          ]
        ]
      );
    }

    {
      name = "Dock";
      anchor = cosmicLib.cosmic.mkRON "enum" "Bottom";
      size = cosmicLib.cosmic.mkRON "enum" "L";
      anchor_gap = true;
      margin = 8;

      plugins_center = cosmicLib.cosmic.mkRON "optional" [
        "com.system76.CosmicPanelAppButton"
      ];
    }
  ];

  # Keep COSMIC-native basics available while retaining Ghostty as the
  # preferred terminal configured in ghostty.nix.
  programs.cosmic-files.enable = true;

  # cosmic-edit currently has a stale fixed-output source hash in the pinned
  # nixpkgs/COSMIC package set. Leave it out until upstream repairs the package
  # so the workstation remains substitute-friendly and does not require a
  # local hash override.
}
