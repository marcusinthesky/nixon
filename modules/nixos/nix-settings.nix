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
      http-connections = 50; # max parallel HTTP connections (default: 25)
      max-substitution-jobs = 32; # max concurrent nar fetches  (default: 16)
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
