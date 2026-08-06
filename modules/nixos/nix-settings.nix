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

      # Build parallelism, download concurrency, and the free-space
      # thresholds are machine capacity, not policy — each host sets them in
      # its platform module under modules/nixos/hardware/.
    };

    gc = {
      automatic = true;
      dates = "Sun 03:00";
      options = "--delete-older-than 14d";
    };
  };
}
