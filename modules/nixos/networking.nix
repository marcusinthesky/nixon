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
    allowedTCPPorts = [
      22 # SSH
    ];
  };
}
