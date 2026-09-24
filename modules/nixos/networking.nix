# Networking — OpenSSH, Mosh, Tailscale, firewall, NetworkManager
_:

{
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;
  };

  # ── SSH (hardened — key-only, no root login) ───────────────────────
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ── Mosh (roaming shell for the phone) ────────────────────────────
  # Moshi's Easy Pair offers SSH or Mosh. Over a phone connection Mosh is the
  # better half of that choice: the session survives the handset changing
  # network, sleeping, or moving between cells, which plain SSH does not.
  #
  # openFirewall is left off on purpose. The module's own rule would open
  # UDP 60000-61000 on every interface; the per-interface rule below keeps
  # Mosh on the same tailnet-only footing as SSH.
  programs.mosh = {
    enable = true;
    openFirewall = false;
  };

  # ── Tailscale VPN ─────────────────────────────────────────────────
  services.tailscale = {
    enable = true;

    # Open UDP 41641 so peers can establish *direct* WireGuard connections.
    # Without it Tailscale still works — it falls back to relaying through
    # DERP servers — but every byte then takes a detour via Tailscale's
    # infrastructure. That is the difference between a responsive remote
    # shell and a laggy one, and it matters far more for `just switch-on`,
    # which pushes build closures between the two machines.
    openFirewall = true;
  };

  # ── Firewall ──────────────────────────────────────────────────────
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8010 ]; # VLC → Chromecast local media streaming

    # SSH is reachable through the tailnet, never directly from LAN/WAN.
    # Mosh follows the same rule: one UDP port per concurrent session, and
    # only from peers that already cleared Tailscale's own authentication.
    # moshi-hook's gateway needs nothing here — it binds 127.0.0.1 and the
    # phone reaches it through the SSH connection.
    interfaces."tailscale0" = {
      allowedTCPPorts = [ 22 ];
      allowedUDPPortRanges = [{ from = 60000; to = 60010; }];
    };
  };
}
