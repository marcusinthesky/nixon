{
  description = "nixon — declarative NixOS workstation configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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

    cosmic-manager = {
      url = "github:HeitorAugustoLN/cosmic-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Project-local toolchain integrations. These remain available for real
    # manifests under tools/ and are kept in the root lockfile.
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";
    };

    cargo2nix = {
      url = "github:cargo2nix/cargo2nix/release-0.12";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    };

    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Bleeding-edge channel — used selectively (e.g. VS Code)
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, vulnix, stylix, cosmic-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      toolPackages = import ./nix/tools.nix { inherit pkgs; };
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
          # ── Host-specific (boot, LUKS, hardware) ───────────────────
          ./hosts/nixos

          # ── COSMIC desktop ────────────────────────────────────────
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
                cosmic-manager.homeManagerModules.cosmic-manager
              ];
              extraSpecialArgs = {
                userName = "marcussky";
                inherit pkgs-unstable toolPackages;
              };
              users.marcussky = import ./home/marcussky;
            };
          }
        ];
      };

      # ════════════════════════════════════════════════════════════════
      # Quality gates — standalone prek (Rust pre-commit replacement)
      # ════════════════════════════════════════════════════════════════
      # Run manually: `prek run --all-files`
      # Install Git hooks: `prek install`
      checks.${system}.prek = pkgs.runCommand "nixon-prek-check"
        {
          nativeBuildInputs = [
            pkgs.prek
            pkgs.nixpkgs-fmt
            pkgs.statix
            pkgs.deadnix
            pkgs.convco
            pkgs.git
            pkgs.rumdl
            pkgs.codespell
            pkgs.tombi
            pkgs.just
            pkgs.just-lsp
          ];
        } ''
        cp -R ${./.} source
        chmod -R u+w source
        export XDG_CACHE_HOME="$TMPDIR/prek-cache"
        mkdir -p "$XDG_CACHE_HOME"
        cd source
        git init -q
        git config user.email "nixon@localhost"
        git config user.name "nixon"
        git add -A
        prek run --all-files
        touch $out
      '';

      # ════════════════════════════════════════════════════════════════
      # Development shell — hooks auto-install on entry
      # ════════════════════════════════════════════════════════════════
      devShells.${system}.default =
        pkgs.mkShell {
          name = "nixon-dev";
          buildInputs = [
            pkgs.prek
            pkgs.just
            pkgs.nixpkgs-fmt
            pkgs.statix
            pkgs.deadnix
            pkgs.convco
            pkgs.rumdl
            pkgs.codespell
            pkgs.tombi
            pkgs.just-lsp
            vulnix.packages.${system}.default
          ];
        };

      # ════════════════════════════════════════════════════════════════
      # Formatter for `nix fmt`
      # ════════════════════════════════════════════════════════════════
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
