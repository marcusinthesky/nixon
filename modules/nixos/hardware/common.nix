# Hardware tuning shared by every host.
#
# Machine-independent policy only. Anything that depends on the CPU vendor,
# the GPU, the amount of RAM, or the class of machine (laptop vs desktop)
# belongs in the per-platform module next to this file:
#
#   xps13.nix        Dell XPS 13 7390  — Intel Ice Lake laptop
#   workstation.nix  AM5 desktop       — Ryzen 9000 + NVIDIA
{ lib, ... }:

{
  boot = {
    # zstd initrd — several times faster to decompress than xz, and the
    # size difference is irrelevant on any disk either host has.
    initrd.compressor = "zstd";

    loader.systemd-boot.configurationLimit = 10;

    # /tmp lives on the root filesystem, so nothing reclaims it on its own.
    # Agent and build scratch (uv, prek, matplotlib, nix-shell) accumulates
    # there indefinitely — it had reached 18 GB before this was set.
    #
    # NOT useTmpfs: that backs /tmp with RAM, and single builds here have
    # written multi-GB caches to it, which trades a disk problem for an OOM.
    tmp.cleanOnBoot = true;

    kernel.sysctl = {
      # Treat compressed zram as a normal reclaim target. Its higher swap
      # priority keeps the encrypted NVMe swap as a last-resort fallback.
      "vm.swappiness" = 100;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 10;
      "vm.dirty_background_ratio" = 5;

      # BBR congestion control + fq qdisc — lower bufferbloat.
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.default_qdisc" = "fq";
    };
  };

  services = {
    # NVMe scheduler = `none` — the device has its own queue depth;
    # bfq/mq-deadline just add overhead.
    udev.extraRules = ''
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    '';

    # Periodic trim for the NVMe SSD. Requires `allowDiscards` on the LUKS
    # container, which each host sets in its own `boot.initrd.luks.devices`.
    fstrim.enable = true;

    # Sized per platform — a laptop SSD and a 1 TB workstation drive do not
    # deserve the same journal budget.
    journald.extraConfig = lib.mkDefault ''
      SystemMaxUse=500M
      MaxRetentionSec=1month
    '';
  };

  # ── Storage ─────────────────────────────────────────────────────────
  fileSystems."/".options = [ "noatime" ];

  # ── Memory pressure: zram ahead of encrypted disk swap ──────────────
  # The LUKS swap declared in hardware-configuration.nix is kept as a
  # last-resort fallback; zram at priority 100 wins for cold pages.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = lib.mkDefault 50;
    priority = 100;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
