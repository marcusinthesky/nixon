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

    # Declarative disk layout. Makes partitioning, LUKS, and formatting part
    # of the configuration rather than a sequence of commands typed once and
    # then forgotten.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
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

    # Bleeding-edge channel — used selectively (COSMIC, VS Code, agent CLIs)
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, vulnix, stylix, cosmic-manager, disko, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      toolPackages = import ./nix/tools.nix { inherit pkgs; };

      userName = "marcussky";
      userDescription = "Marcus Gawronsky";

      # ── sharedModules ───────────────────────────────────────────────
      # Everything that is true of "a nixon machine" regardless of which
      # machine. Both real hosts and the installer image are built from
      # this list, which is what makes the live ISO a working workstation
      # rather than a stripped-down rescue environment.
      sharedModules = [
        # ── COSMIC desktop ────────────────────────────────────────
        ./modules/nixos/cosmic-unstable.nix

        # ── Shared NixOS modules ───────────────────────────────────
        ./modules/nixos/nix-settings.nix
        ./modules/nixos/hardware/common.nix
        ./modules/nixos/desktop.nix
        ./modules/nixos/networking.nix
        ./modules/nixos/security.nix
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
              inherit userName pkgs-unstable toolPackages;
            };
            users.${userName} = import ./home/marcussky;
          };
        }
      ];

      # ── mkSystem ────────────────────────────────────────────────────
      # specialArgs is passed to every NixOS module (including Home
      # Manager). `self` is here so the installer image can bundle this
      # flake's source onto the ISO.
      mkSystem = modules: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit self userName userDescription pkgs-unstable;
        };
        modules = sharedModules ++ modules;
      };

      # ── mkHost ──────────────────────────────────────────────────────
      # One workstation profile, several machines. The host directory owns
      # boot, disks, identity, and its platform tuning module. Add a host
      # by creating hosts/<name>/ and adding one line below.
      mkHost = hostPath: mkSystem [
        disko.nixosModules.disko
        hostPath
      ];
    in
    {
      # ════════════════════════════════════════════════════════════════
      # NixOS system configurations
      # ════════════════════════════════════════════════════════════════
      nixosConfigurations = {
        # Dell XPS 13 7390 — Intel Ice Lake laptop
        nixos = mkHost ./hosts/nixos;

        # AM5 desktop — Ryzen 5 9600X + RTX 5060 Ti, driven over SSH
        workstation = mkHost ./hosts/workstation;

        # Live installer image — the workstation profile itself, plus the
        # ISO machinery. Not a mkHost: it deliberately omits hosts/
        # workstation, because the disk layout and bootloader belong to the
        # machine being installed, not to the stick doing the installing.
        installer = mkSystem [
          ./modules/nixos/hardware/workstation.nix
          ./hosts/installer
        ];
      };

      # ════════════════════════════════════════════════════════════════
      # Installer ISO — `just iso`, then `just flash`
      # ════════════════════════════════════════════════════════════════
      packages.${system}.installer-iso =
        self.nixosConfigurations.installer.config.system.build.isoImage;

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
