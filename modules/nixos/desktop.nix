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
  # omit optional applications that are not part of this workstation profile.
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-reader
    cosmic-term
  ];

  # RealtimeKit — lets PipeWire acquire realtime scheduling
  security.rtkit.enable = true;
}
