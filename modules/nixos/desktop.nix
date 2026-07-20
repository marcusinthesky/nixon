# COSMIC Desktop Environment — COSMIC greeter, Wayland, printing, audio
_:

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

  # RealtimeKit — lets PipeWire acquire realtime scheduling
  security.rtkit.enable = true;
}
