# Security — on-demand malware scanning
{ pkgs, ... }:

{
  # ── ClamAV ──────────────────────────────────────────────────────────
  # On-demand `clamscan` for spot-checking downloads. No on-access daemon
  # (that's a much heavier real-time scanner) — just the CLI plus a timer
  # to keep virus definitions current.
  environment.systemPackages = [ pkgs.clamav ];

  services.clamav = {
    daemon.enable = false;
    updater.enable = true;
  };
}
