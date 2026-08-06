# Live installer image — the nixon workstation, on a stick.
#
# Built by `just iso`, written by `just flash`.
#
# This is not the stock NixOS installer with a few extras bolted on. It is
# the workstation profile itself (see `sharedModules` in flake.nix) plus the
# ISO machinery, which is what makes the live session a working desktop:
# the real NVIDIA driver, COSMIC, the shell, the whole Home Manager profile.
#
# That matters for one specific reason. Stock installer images ship nouveau,
# which cannot drive Blackwell (GB206). The failure is not a hang — the
# kernel stays up and answers Ctrl+Alt+Del — but cosmic-greeter takes the DRM
# device and the VT, fails, and leaves a black screen with no console to
# switch back to. Shipping the driver the target actually needs removes the
# whole class of problem.
#
# What it deliberately does NOT include is hosts/workstation: disks,
# bootloader, and identity belong to the machine being installed.
{ config, lib, pkgs, modulesPath, self, userName, userDescription, ... }:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix")
  ];

  image.baseName = lib.mkForce "nixon-installer-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";

  # The default is `zstd -Xcompression-level 6`, tuned for images that get
  # downloaded by many people. This one is built on a 4-core laptop and
  # written to a 57 GB stick, so trading image size for compression time is
  # the right way round — squashing the closure is the longest step in the
  # build by a wide margin.
  isoImage.squashfsCompression = "zstd -Xcompression-level 3";

  networking.hostName = lib.mkForce "nixon-installer";

  # ── The installer ────────────────────────────────────────────────────
  environment.etc = {
    "nixon/install.sh" = {
      source = ../../nix/install.sh;
      mode = "0755";
    };
    # This flake, so the install needs no network access to GitHub and no
    # credentials. Package downloads still need a working connection.
    "nixon/flake".source = self.outPath;
  };

  environment.systemPackages =
    let
      launcher = pkgs.writeShellScript "nixon-install-launcher" ''
        exec ${lib.getExe pkgs.cosmic-term} -e sudo /etc/nixon/install.sh
      '';
    in
    [
      (pkgs.makeDesktopItem {
        name = "nixon-install";
        desktopName = "Install nixon";
        exec = toString launcher;
        icon = "system-software-install";
        comment = "Install this NixOS workstation to the internal NVMe";
      })
    ]
    ++ (with pkgs; [
      cosmic-term
      disko
      cryptsetup
      gptfdisk
      parted
      gparted
      git
      just
    ]);

  # Put it on the live desktop, next to nothing else.
  systemd.tmpfiles.rules = [
    "d /home/${userName}/Desktop 0755 ${userName} users - -"
    "L+ /home/${userName}/Desktop/nixon-install.desktop 0644 ${userName} users - /run/current-system/sw/share/applications/nixon-install.desktop"
  ];

  # ── Live session identity ────────────────────────────────────────────
  # The Home Manager profile in sharedModules is attached to this user, so
  # the live session has to log in as them rather than the ISO's `nixos`
  # account — otherwise none of the configured desktop shows up.
  users.users.${userName} = {
    isNormalUser = true;
    description = userDescription;
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    # Live media only. The installed system sets a real password during
    # step 3 of install.sh.
    initialHashedPassword = "";
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = userName;
  };

  security.sudo.wheelNeedsPassword = false;

  # ── ISO-specific overrides ───────────────────────────────────────────
  # Plymouth hides exactly the output you need when a live image misbehaves
  # on unfamiliar hardware, and it is where the nouveau failure surfaced.
  boot.plymouth.enable = lib.mkForce false;

  # Docker and the container toolkit are dead weight on a live image, and
  # the daemon has nowhere persistent to write.
  virtualisation.docker.enable = lib.mkForce false;
  hardware.nvidia-container-toolkit.enable = lib.mkForce false;

  # Collecting garbage from the store the live system is running out of.
  nix.gc.automatic = lib.mkForce false;

  # The installer image carries ZFS. Nothing here imports a ZFS root, and
  # this is the 26.11 default.
  boot.zfs.forceImportRoot = false;

  # Nothing to swap to on a live stick.
  swapDevices = lib.mkForce [ ];

  # The NVIDIA driver is the reason this image exists; hosts/ normally
  # carries this, and the installer has no host module.
  nixpkgs.config.allowUnfree = true;
}
