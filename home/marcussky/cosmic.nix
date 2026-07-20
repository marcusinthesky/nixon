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

    # Keep the top panel as a thin system/status bar and put the application
    # launcher/task list in a separate bottom dock.
    panels = [
      {
        name = "Panel";
        anchor = cosmicLib.cosmic.mkRON "enum" "Top";
        # COSMIC's small panel size keeps the status bar visually lighter.
        size = cosmicLib.cosmic.mkRON "enum" "S";
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
        expand_to_edges = false;
        anchor_gap = true;
        margin = 8;

        plugins_center = cosmicLib.cosmic.mkRON "optional" [
          "com.system76.CosmicPanelAppButton"
          "com.system76.CosmicAppList"
        ];
      }
    ];

    # The App Tray is the COSMIC dock's pinned/running application list.
    # Desktop-file IDs are used here, without the `.desktop` suffix.
    applets.app-list.settings.favorites = [
      "firefox"
      "com.mitchellh.ghostty"
      "google-chrome"
      "dev.zed.Zed"
      "com.system76.CosmicEdit"
      "io.missioncenter.MissionCenter"
    ];

    # Arrange workspaces left-to-right so touchpad gestures and workspace
    # navigation follow the usual horizontal desktop convention.
    compositor.workspaces.workspace_layout =
      cosmicLib.cosmic.mkRON "enum" "Horizontal";
    compositor.workspaces.workspace_mode =
      cosmicLib.cosmic.mkRON "enum" "OutputBound";

    # Keep the GNOME-style current-workspace overview action explicit.
    # COSMIC currently exposes this as a shortcut, not as a configurable
    # touchpad-gesture binding.
    shortcuts = [
      {
        key = "Super+W";
        action = cosmicLib.cosmic.mkRON "enum" {
          value = [
            (cosmicLib.cosmic.mkRON "enum" "WorkspaceOverview")
          ];
          variant = "System";
        };
        description = cosmicLib.cosmic.mkRON "optional" "Show workspace overview";
      }
    ];

    # The panel layout module does not expose border_radius directly, so set
    # the dock component's native COSMIC config entry explicitly.
    configFile."com.system76.CosmicPanel.Dock" = {
      version = 1;
      entries.border_radius = 16;
    };
  };

  # Keep COSMIC-native basics available while retaining Ghostty as the
  # preferred terminal configured in ghostty.nix.
  programs.cosmic-files.enable = true;

}
