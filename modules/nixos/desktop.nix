# COSMIC Desktop Environment — COSMIC greeter, Wayland, printing, audio
{ pkgs, ... }:

{
  services = {
    # ── Display & Desktop ──────────────────────────────────────────────
    displayManager.cosmic-greeter.enable = true;
    desktopManager.cosmic.enable = true;

    # ── Firmware updates ───────────────────────────────────────────────
    fwupd.enable = true;

    # ── Printing ───────────────────────────────────────────────────────
    printing.enable = true;

    # ── Audio (PipeWire) ───────────────────────────────────────────────
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  # COSMIC installs its own applications by default. Keep the desktop but
  # avoid the known stale cosmic-edit fixed-output package in nixpkgs.
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-edit
    cosmic-player
    cosmic-reader
    cosmic-term
    cosmic-wallpapers
  ];

  # RealtimeKit — lets PipeWire acquire realtime scheduling
  security.rtkit.enable = true;
}
