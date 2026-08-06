# Nix daemon settings — flakes, store optimisation, garbage collection
_:

{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # Hash deduplication is useful for disk usage but adds work during every
      # activation. Prefer faster switches; run store optimisation manually
      # when disk usage warrants it.
      auto-optimise-store = false;
      trusted-users = [ "root" "@wheel" ];

      # ── Binary cache mirrors ─────────────────────────────────────────
      substituters = [
        "https://cache.nixos.org"
        "https://nix-mirror.freetls.fastly.net" # Fastly CDN — global edge nodes
        "https://cosmic.cachix.org/"
      ];
      trusted-public-keys = [
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
      ];

      # ── Download parallelism ─────────────────────────────────────────
      # Keep concurrent nar downloads from turning this SSD's limited
      # sustained-write throughput into an I/O latency spike.
      http-connections = 16;
      max-substitution-jobs = 4;

      # Bound local CPU and I/O pressure to the laptop's eight hardware
      # threads while retaining enough headroom for an interactive desktop.
      max-jobs = 4;
      cores = 2;

      # If the store drives root below 10 GiB free, collect unreachable paths
      # until 20 GiB is available. Live profiles and generations remain roots.
      min-free = 10 * 1024 * 1024 * 1024;
      max-free = 20 * 1024 * 1024 * 1024;
    };

    gc = {
      automatic = true;
      dates = "Sun 03:00";
      options = "--delete-older-than 14d";
    };
  };
}
