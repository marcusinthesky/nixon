# Platform: AM5 compute workstation
#
#   CPU   AMD Ryzen 5 9600X (Zen 5, 6C/12T, 3.9 GHz base / 5.4 GHz boost)
#   Board MSI B650 (mATX)
#   RAM   32 GB DDR5-6000 (2 × 16 GB) — enable EXPO in UEFI or it runs at 4800
#   GPU   MSI GeForce RTX 5060 Ti 16 GB (Blackwell, GB206)
#   Disk  1 TB Gen4 NVMe
#
# This box is driven over SSH for compute, so the priorities are inverted
# relative to the laptop: boot reliability and unattended uptime beat
# desktop-latency tuning and idle power.
{ config, pkgs, ... }:

{
  boot = {
    # The mainline kernel, NOT zen. The NVIDIA kernel module is out-of-tree
    # and is the single most likely thing to fail a `nix flake update`; zen
    # tracks the newest mainline releases within days, which is exactly where
    # that breaks. The zen tick-rate/PREEMPT wins were bought to fix XPS 13
    # desktop stutter under thermal throttling — a problem this machine does
    # not have. Switch to `pkgs.linuxPackages_zen` if you end up using this
    # box as a daily-driver desktop and accept the update risk.
    kernelPackages = pkgs.linuxPackages;

    kernelModules = [ "kvm-amd" ];

    kernelParams = [
      # amd-pstate in EPP mode. Zen 5 exposes full CPPC, so the firmware
      # picks frequencies from a performance hint instead of the kernel
      # stepping through discrete P-states — better boost residency and
      # noticeably faster ramp-up than the legacy acpi-cpufreq path.
      "amd_pstate=active"
    ];
  };

  hardware = {
    # Realtek/Intel NIC, Wi-Fi, and AMD microcode all need redistributable
    # firmware. Without this the onboard networking may not come up at all,
    # which on a headless box means no way in.
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;

    # ── NVIDIA (RTX 5060 Ti, Blackwell GB206) ─────────────────────────
    nvidia = {
      # MANDATORY on Blackwell. NVIDIA ships no proprietary kernel module
      # for GB20x — the open module is the only one that binds this GPU.
      # It is also what `nvidia.open` gates the GSP firmware path on.
      open = true;

      # Latest stable branch; resolves to `production` (595.71.05 as
      # pinned). 5060 Ti needs >= 570, so there is no legacy fallback here.
      branch = "stable";

      # Provides the driver's own framebuffer device (>= 545), which is what
      # lets a Wayland compositor like COSMIC come up on NVIDIA at all.
      # Also implies `nvidia-drm.fbdev=1`, so the TTYs stay usable.
      modesetting.enable = true;

      # Keeps the driver initialised with no client attached. On a compute
      # box this removes the multi-second device re-initialisation at the
      # start of every CUDA process and keeps `nvidia-smi` responsive for
      # remote monitoring.
      nvidiaPersistenced = true;
    };

    # `docker run --gpus all` / CDI device injection. Pairs with the Docker
    # daemon from modules/nixos/docker.nix.
    nvidia-container-toolkit.enable = true;
  };

  # Loads the NVIDIA driver and is what flips `hardware.nvidia.enabled`.
  # Required even though the session is Wayland-only.
  services.xserver.videoDrivers = [ "nvidia" ];

  services = {
    # No thermald: it is an Intel DPTF daemon and does nothing on AMD.
    # Zen 5 boost behaviour is managed entirely by the firmware and
    # amd-pstate.
    #
    # power-profiles-daemon is kept so the COSMIC power applet works. It
    # drives the amd-pstate energy-performance preference; for a long
    # unattended run pin it with `powerprofilesctl set performance`.
    power-profiles-daemon.enable = true;

    # 1 TB of disk and a machine that is debugged after the fact over SSH.
    # A 500 MB journal loses the evidence long before you go looking.
    journald.extraConfig = ''
      SystemMaxUse=2G
      MaxRetentionSec=3month
    '';
  };

  # ── Stay awake ───────────────────────────────────────────────────────
  # A desktop-class install will happily suspend on graphical idle, which
  # on this machine means killing a long-running job and dropping every SSH
  # session because the box is asleep. There is no battery to protect.
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowSuspendThenHibernate = "no";
    AllowHybridSleep = "no";
  };

  # ── Memory ───────────────────────────────────────────────────────────
  # 32 GB, so 8 GB of compressed swap is enough of a cushion to survive a
  # memory spike without spending real RAM on the compressed pool. The
  # laptop's 50 % made sense at 16 GB; here it would cost too much.
  zramSwap.memoryPercent = 25;

  # ── CUDA from non-Nix binaries ───────────────────────────────────────
  # pip/uv wheels (torch, jax, onnxruntime) dlopen `libcuda.so.1`, which
  # only ever comes from the running driver — never from a wheel. Exposing
  # it through nix-ld fixes `torch.cuda.is_available() == False` without
  # polluting the global LD_LIBRARY_PATH the way the usual workaround does.
  programs.nix-ld.libraries = [ config.hardware.nvidia.package ];

  # ── Build capacity ───────────────────────────────────────────────────
  # 6 cores / 12 threads and a Gen4 NVMe. Wide rather than deep: nixpkgs is
  # mostly many small derivations, so parallel jobs beat parallel cores.
  nix.settings = {
    max-jobs = 6;
    cores = 2;

    # Gigabit LAN and a drive that can absorb the concurrent writes.
    http-connections = 50;
    max-substitution-jobs = 16;

    # Roomier than the laptop's thresholds — 1 TB can carry more history
    # between collections, and this host builds for two machines.
    min-free = 20 * 1024 * 1024 * 1024;
    max-free = 50 * 1024 * 1024 * 1024;
  };

  # Sensor telemetry, on the host that actually has it.
  #
  # Deliberately NOT nvtopPackages.nvidia: it depends on cuda-merged, which
  # drags several GB of CUDA toolkit into the system closure for a process
  # monitor. `nvidia-smi` ships with the driver and covers the same ground;
  # reach for nvtop ad hoc with `nix shell nixpkgs#nvtopPackages.nvidia`.
  environment.systemPackages = [ pkgs.lm_sensors ];
}
