# Host: nixos — Marcus's personal workstation
#
# Machine-specific configuration: boot, LUKS encryption, hostname,
# and hardware. Everything else is in shared modules.
{ pkgs, userName, userDescription, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # --------------------------------------------------------------------------
  # Boot & Encryption
  # --------------------------------------------------------------------------
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    # dm-crypt discards TRIM requests unless told otherwise, so `fstrim`
    # returned "the discard operation is not supported" and the SSD never
    # learned which blocks were free. On this DRAM-less TLC drive that meant
    # read-modify-erase on every write: measured 24 MB/s sequential write
    # against ~685 MB/s read, roughly micro-SD speed.
    #
    # SECURITY: passing discards through leaks the *pattern* of used vs free
    # blocks to anyone with offline access to the disk — it reveals roughly
    # how full the volume is and where data sits, though never its contents.
    # Standard laptop trade-off, and the alternative is a crippled drive.
    #
    # The root device is declared in hardware-configuration.nix (generated);
    # the module system merges this attribute into it.
    initrd.luks.devices = {
      "luks-dcda9499-a7ef-4a11-b1c3-762e6a7ce582".allowDiscards = true;

      # Swap has no discard option, so keep its allocation pattern private.
      "luks-60a07f23-65d2-4af8-b2ae-95378e57301d" = {
        device = "/dev/disk/by-uuid/60a07f23-65d2-4af8-b2ae-95378e57301d";
      };
    };
  };

  # --------------------------------------------------------------------------
  # Identity
  # --------------------------------------------------------------------------
  networking.hostName = "nixos";

  time.timeZone = "Africa/Johannesburg";
  i18n.defaultLocale = "en_GB.UTF-8";

  # --------------------------------------------------------------------------
  # User account
  # --------------------------------------------------------------------------
  users.users.${userName} = {
    isNormalUser = true;
    description = userDescription;
    extraGroups = [
      "networkmanager"
      "wheel" # sudo
      "docker" # Docker without sudo
    ];
    shell = pkgs.zsh;
  };

  # --------------------------------------------------------------------------
  # Allow unfree packages (VS Code, Chrome, etc.)
  # --------------------------------------------------------------------------
  nixpkgs.config.allowUnfree = true;

  # --------------------------------------------------------------------------
  # State version — do not change after initial install
  # --------------------------------------------------------------------------
  system.stateVersion = "25.11";
}
