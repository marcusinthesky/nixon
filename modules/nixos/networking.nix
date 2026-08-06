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
  services.tailscale.enable = true;

  # ── Firewall ──────────────────────────────────────────────────────
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8010 ]; # VLC → Chromecast local media streaming

    # SSH is reachable through the tailnet, never directly from LAN/WAN.
    interfaces."tailscale0".allowedTCPPorts = [ 22 ];
  };
}
