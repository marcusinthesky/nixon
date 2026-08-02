# Hardware tuning — Dell XPS 13 7390 (i7-1065G7, 16 GB LPDDR4x)
#
# Targets the real bottlenecks on this machine:
#   • Slow LPDDR4x + encrypted disk swap  → zram in RAM
#   • Ice Lake thermal throttling          → thermald
#   • DE stutter under load                 → zen kernel (1000 Hz, PREEMPT)
#   • CPU-decoded video                    → Intel VAAPI (iHD)
{ config, pkgs, ... }:

{
  # ── Kernel & boot ────────────────────────────────────────────────────
  # zen: 1000 Hz tick, full PREEMPT, EEVDF tuned for interactivity.
  # Use the zen kernel *packages set* so extra modules (acpi_call, etc.)
  # track the zen kernel rather than the default LTS.
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;

    # i915 HuC authentication (bit 1 of enable_guc) — loads the HuC
    # firmware so the media pipeline can offload video decode/encode to
    # fixed-function hardware. GuC submission (bit 0) is NOT supported on
    # Ice Lake Gen11, so we request value 2 (HuC only) rather than 3.
    # The "Setting dangerous option" taint in dmesg is i915's standard
    # warning for this param and is cosmetic.
    # Requires the HuC firmware (pulled in by linux-firmware).
    kernelParams = [ "i915.enable_guc=2" ];

    # SECURITY: re-enable these on any untrusted-input workload.
    #   kernelParams = lib.mkAfter [ "mitigations=off" ];

    # zstd initrd — ~3× faster decompression than xz on Ice Lake cores.
    initrd.compressor = "zstd";

    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ config.boot.kernelPackages.acpi_call ];

    loader.systemd-boot.configurationLimit = 10;

    # /tmp lives on the root filesystem, so nothing reclaims it on its own.
    # Agent and build scratch (uv, prek, matplotlib, nix-shell) accumulates
    # there indefinitely — it had reached 18 GB before this was set.
    #
    # NOT useTmpfs: that backs /tmp with RAM, and single builds here have
    # written multi-GB caches to it. On 16 GB that trades a disk problem
    # for an OOM.
    tmp.cleanOnBoot = true;

    # Only swap to disk under real pressure — zram absorbs the rest.
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 10;
      "vm.dirty_background_ratio" = 5;

      # BBR congestion control + fq qdisc — lower bufferbloat on Wi-Fi.
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.default_qdisc" = "fq";
    };
  };

  # ── Thermal & power ──────────────────────────────────────────────────
  # thermald is mandatory on XPS 13 — without it the 7390 rides the
  # thermal envelope by brute throttling, which is the #1 cause of
  # "DE freezes for half a second" on Ice Lake.
  services = {
    thermald.enable = true;

    # power-profiles-daemon owns the cpufreq governor and exposes
    # `performance` on AC and `power-saver` on battery to the desktop.
    power-profiles-daemon.enable = true;

    # NVMe scheduler = `none` — the device has its own queue depth;
    # bfq/mq-deadline just add overhead.
    udev.extraRules = ''
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    '';

    # Periodic trim for the NVMe SSD.
    fstrim.enable = true;

    # The 7390's SSD doesn't deserve an unbounded journal.
    journald.extraConfig = ''
      SystemMaxUse=500M
      MaxRetentionSec=1month
    '';
  };

  # ── Storage ─────────────────────────────────────────────────────────
  fileSystems."/".options = [ "noatime" ];

  # ── Memory pressure: zram instead of encrypted disk swap ────────────
  # The hardware-configuration.nix LUKS swap is kept as a last-resort
  # fallback; zram at priority 100 wins for cold pages.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # up to 8 GB compressed swap in RAM
    priority = 100;
  };

  # ── Hardware video decode (Iris Plus Gen11) ──────────────────────────
  # intel-media-driver = iHD — covers Gen8 through Gen12.
  # (vpl-gpu-rt is for Gen12+ Xe only — not needed on Ice Lake.)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [ pkgs.intel-media-driver ];
  };
}
