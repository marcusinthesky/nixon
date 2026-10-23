# Hardware facts for the AM5 workstation.
#
# Hand-written rather than generated. Everything `nixos-generate-config`
# would contribute about disks — `fileSystems`, `swapDevices`,
# `boot.initrd.luks.devices` — is owned by ./disk-config.nix instead, so
# there is no generated file to import and nothing to keep in sync.
#
# What remains is the part a scan cannot infer ahead of the hardware
# existing: which modules stage 1 needs.
{ config, lib, ... }:

{
  boot.initrd.availableKernelModules = [
    # Storage
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"

    # Networking, required in stage 1 for the remote LUKS unlock. MSI B650
    # boards ship either a Realtek 2.5G (r8169) or an Intel (igc) NIC;
    # including both costs nothing, and udev loads only what matches.
    "r8169"
    "igc"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
