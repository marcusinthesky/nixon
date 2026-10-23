# Networking — OpenSSH, Tailscale, firewall, NetworkManager
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
    interfaces."tailscale0".allowedTCPPorts = [ 22 ];
  };
}
