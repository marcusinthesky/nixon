# Platform: Dell XPS 13 7390 — Intel Core i7-1065G7 (Ice Lake), 16 GB LPDDR4x
#
# Targets the real bottlenecks on this machine:
#   • Slow LPDDR4x + encrypted disk swap  → zram in RAM (see hardware/common.nix)
#   • Ice Lake thermal throttling          → thermald
#   • DE stutter under load                → zen kernel (1000 Hz, PREEMPT)
#   • CPU-decoded video                    → Intel VAAPI (iHD)
{ config, pkgs, ... }:

{
  boot = {
    # zen: 1000 Hz tick, full PREEMPT, EEVDF tuned for interactivity.
    # Use the zen kernel *packages set* so extra modules (acpi_call, etc.)
    # track the zen kernel rather than the default LTS.
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

    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
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

    # The 7390's SSD doesn't deserve an unbounded journal.
    journald.extraConfig = ''
      SystemMaxUse=500M
      MaxRetentionSec=1month
    '';
  };

  # ── Hardware video decode (Iris Plus Gen11) ──────────────────────────
  # intel-media-driver = iHD — covers Gen8 through Gen12.
  # (vpl-gpu-rt is for Gen12+ Xe only — not needed on Ice Lake.)
  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];

  # ── Build capacity ───────────────────────────────────────────────────
  # Bound local CPU and I/O pressure to this machine's eight hardware
  # threads while retaining enough headroom for an interactive desktop.
  nix.settings = {
    max-jobs = 4;
    cores = 2;

    # Keep concurrent nar downloads from turning this SSD's limited
    # sustained-write throughput into an I/O latency spike.
    http-connections = 16;
    max-substitution-jobs = 4;

    # If the store drives root below 10 GiB free, collect unreachable paths
    # until 20 GiB is available. Live profiles and generations remain roots.
    min-free = 10 * 1024 * 1024 * 1024;
    max-free = 20 * 1024 * 1024 * 1024;
  };
}
