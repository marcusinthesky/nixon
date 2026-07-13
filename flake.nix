{
  description = "nixify — declarative NixOS workstation configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vulnix = {
      url = "github:nix-community/vulnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Bleeding-edge channel — used selectively (e.g. VS Code)
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    zed-extensions.url = "github:DuskSystems/nix-zed-extensions";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, git-hooks, vulnix, stylix, zed-extensions, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      # ════════════════════════════════════════════════════════════════
      # NixOS system configuration
      # ════════════════════════════════════════════════════════════════
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;

        # ── specialArgs ────────────────────────────────────────────────
        # Passed to every NixOS module (including Home Manager).
        # Add new hosts by duplicating this block with different args.
        specialArgs = {
          userName = "marcussky";
          userDescription = "Marcus Gawronsky";
        };

        modules = [
          # ── Zed extensions overlay ────────────────────────────────────
          { nixpkgs.overlays = [ zed-extensions.overlays.default ]; }

          # ── Host-specific (boot, LUKS, hardware) ───────────────────
          ./hosts/nixos

          # ── Shared NixOS modules ───────────────────────────────────
          ./modules/nixos/nix-settings.nix
          ./modules/nixos/hardware-tuning.nix
          ./modules/nixos/desktop.nix
          ./modules/nixos/networking.nix
          ./modules/nixos/docker.nix
          ./modules/nixos/shell.nix
          ./modules/nixos/stylix.nix

          # ── Theming (Stylix) ────────────────────────────────────────
          stylix.nixosModules.stylix

          # ── Home Manager as NixOS module ───────────────────────────
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              sharedModules = [
                zed-extensions.homeManagerModules.default
              ];
              extraSpecialArgs = {
                userName = "marcussky";
                inherit pkgs-unstable;
              };
              users.marcussky = import ./home/marcussky;
            };
          }
        ];
      };

      # ════════════════════════════════════════════════════════════════
      # Quality gates — pre-commit hooks (Nix-managed, self-contained)
      # ════════════════════════════════════════════════════════════════
      # All tooling is pinned via the flake lock — no system installs
      # needed. Hooks install automatically when entering `nix develop`.
      # Run manually: nix develop -c pre-commit run --all-files
      # Run in CI:    nix flake check (sandboxed, read-only)
      checks.${system} = {
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            # ── Nix formatting ─────────────────────────────────────────
            nixpkgs-fmt.enable = true;

            # ── Nix linting ────────────────────────────────────────────
            statix.enable = true;

            # ── Nix dead code detection ────────────────────────────────
            deadnix.enable = true;

            # ── General hygiene ────────────────────────────────────────
            check-merge-conflicts.enable = true;
            check-added-large-files.enable = true;
            detect-private-keys.enable = true;
            end-of-file-fixer.enable = true;
            trim-trailing-whitespace.enable = true;

            # ── Commit messages ────────────────────────────────────────
            # Enforce conventional commits (feat:, fix:, chore:, etc.)
            convco.enable = true;
          };
        };
      };

      # ════════════════════════════════════════════════════════════════
      # Development shell — hooks auto-install on entry
      # ════════════════════════════════════════════════════════════════
      devShells.${system}.default =
        let
          inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
        in
        pkgs.mkShell {
          name = "nixify-dev";
          inherit shellHook;
          buildInputs = enabledPackages ++ [
            pkgs.just
            pkgs.nixpkgs-fmt
            pkgs.statix
            pkgs.deadnix
            vulnix.packages.${system}.default
          ];
        };

      # ════════════════════════════════════════════════════════════════
      # Formatter for `nix fmt`
      # ════════════════════════════════════════════════════════════════
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
