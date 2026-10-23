# Declarative disk layout — single NVMe, LUKS2, no swap partition.
#
#   1. ESP  (1 GiB)      EFI System Partition, FAT32, mounted at /boot
#   2. LUKS (remainder)  LUKS2 container holding an ext4 root
#
# 1 GiB for the ESP rather than the customary 512 MiB: systemd-boot keeps a
# kernel and initrd per generation on it, `configurationLimit` is 10, and the
# NVIDIA initrds here are not small. 512 MiB fills up and then activation
# starts failing at the least convenient moment.
#
# No swap partition. 32 GB of RAM plus zram covers the pressure, and
# hibernation is deliberately disabled on this host — see
# modules/nixos/hardware/workstation.nix.
#
# This replaces the generated hardware-configuration.nix filesystem stanza:
# disko produces `fileSystems` and `boot.initrd.luks.devices` itself, so the
# device name is never written down twice and cannot drift.
{ lib, ... }:

{
  disko.devices.disk.main = {
    device = lib.mkDefault "/dev/nvme0n1";
    type = "disk";

    content = {
      type = "gpt";
      partitions = {
        esp = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "fmask=0077" "dmask=0077" ];
          };
        };

        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";

            # Prompted once at install time and at every boot. Remote unlock
            # over SSH in the initrd is configured in ./default.nix.
            askPassword = true;

            # Pass TRIM through to the SSD. dm-crypt swallows discards by
            # default, which starves the drive of free-block information and
            # collapses sustained write throughput.
            #
            # SECURITY: this leaks the *pattern* of used vs free blocks to
            # anyone with offline access to the disk — roughly how full the
            # volume is and where data sits, never its contents.
            settings.allowDiscards = true;

            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "noatime" ];
            };
          };
        };
      };
    };
  };
}
