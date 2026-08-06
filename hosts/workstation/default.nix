# Host: workstation — AM5 compute box (Ryzen 5 9600X + RTX 5060 Ti)
#
# Machine-specific configuration: boot, LUKS encryption, remote unlock,
# hostname, and user identity. Platform tuning lives in
# modules/nixos/hardware/workstation.nix; everything else is shared.
{ lib, pkgs, userName, userDescription, ... }:

let
  # Public keys allowed to reach this machine — both the running SSH daemon
  # and the initrd unlock prompt. Fill this in from the laptop:
  #
  #   cat ~/.ssh/id_ed25519.pub
  #
  # Remote LUKS unlock stays switched off while this list is empty, so the
  # flake still evaluates and builds on a machine that has not been keyed yet.
  sshKeys = [
    # "ssh-ed25519 AAAA... marcussky@nixos"
  ];

  remoteUnlock = sshKeys != [ ];
in

{
  imports = [
    ./disk-config.nix
    ./hardware.nix
    ../../modules/nixos/hardware/workstation.nix
  ];

  # --------------------------------------------------------------------------
  # Boot & Encryption
  # --------------------------------------------------------------------------
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      # systemd in stage 1. Required for the SSH unlock below, and it is what
      # turns the LUKS passphrase into a `systemd-ask-password` prompt that a
      # remote agent can answer.
      systemd = {
        enable = true;

        # NetworkManager owns the interface after boot and therefore sets
        # `networking.useDHCP = false`, which leaves stage 1 with no network
        # at all. Declare DHCP explicitly so the unlock prompt is reachable.
        network = lib.mkIf remoteUnlock {
          enable = true;
          networks."10-wired-dhcp" = {
            matchConfig = {
              Type = "ether";
              Kind = "!*"; # physical interfaces only
            };
            networkConfig.DHCP = "yes";
          };
        };
      };

      # Remote unlock. Without this a reboot from an SSH session leaves the
      # machine sitting at a passphrase prompt with no way in short of
      # walking over to it:
      #
      #   ssh -p 2222 root@<workstation>
      #   systemd-tty-ask-password-agent      # then type the passphrase
      #
      # One-time setup on the machine, before the first switch:
      #
      #   sudo mkdir -p /etc/secrets/initrd
      #   sudo ssh-keygen -t ed25519 -N "" -f /etc/secrets/initrd/ssh_host_ed25519_key
      #
      # SECURITY: this host key is embedded in the initrd on the unencrypted
      # ESP, so it must be a dedicated key — never the system's real host key.
      # It is referenced as a string, not a Nix path, so systemd-boot injects
      # it at install time instead of copying it into the world-readable
      # Nix store.
      network.ssh = {
        enable = remoteUnlock;
        port = 2222; # not 22 — stage 2 sshd owns that
        hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
        authorizedKeys = sshKeys;
      };

      # The LUKS container itself — device name, discard policy — is declared
      # in ./disk-config.nix, which is also what creates it. There is no
      # generated UUID to copy in here after the fact.
    };
  };

  # --------------------------------------------------------------------------
  # Identity
  # --------------------------------------------------------------------------
  networking.hostName = "workstation";

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

    # This host is reached over SSH far more than it is sat in front of, and
    # modules/nixos/networking.nix disables password authentication.
    openssh.authorizedKeys.keys = sshKeys;
  };

  # --------------------------------------------------------------------------
  # Allow unfree packages (NVIDIA driver, VS Code, Chrome, etc.)
  # --------------------------------------------------------------------------
  nixpkgs.config.allowUnfree = true;

  # --------------------------------------------------------------------------
  # State version — do not change after initial install
  # --------------------------------------------------------------------------
  system.stateVersion = "26.05";
}
