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
{ config, lib, pkgs, ... }:

let
  theme = import ../../../theme.nix;
in

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

    # ── RGB ────────────────────────────────────────────────────────────
    # The board carries an MSI Mystic Light controller on USB
    # (0db0:0076), which is what the case/CPU fan headers and the board's
    # own zones hang off. Nothing in Linux touches it by default, so the
    # lighting is stuck on whatever the UEFI last wrote.
    #
    # This installs OpenRGB's udev rules — without them the device is
    # root-only and the GUI comes up empty — and runs the SDK server so
    # the lighting survives a reboot and can be driven remotely on 6742.
    #
    # `motherboard` is left at its default, which resolves to "amd" from
    # `hardware.cpu.amd.updateMicrocode` above and pulls in i2c-dev +
    # i2c-piix4. That is the SMBus path, needed for anything addressed
    # over i2c rather than USB — DDR5 DIMM lighting in particular.
    #
    # The colour itself is not set here — see openrgb-apply below. The
    # module's own `startupProfile` is deliberately unused: it wants a
    # binary .orp blob saved from the GUI and copied into
    # /var/lib/OpenRGB by hand, which is exactly the kind of undeclared
    # machine state this flake exists to avoid.
    hardware.openrgb.enable = true;
  };

  # ── Lighting: pin every zone to the theme colour ─────────────────────
  # openrgb.service only exposes the hardware; something still has to
  # tell it what to show, or the board reverts to its UEFI setting.
  #
  # This runs the CLI in client mode against that server rather than
  # touching the devices directly — two processes claiming the same
  # hidraw node is how you get a controller that answers neither.
  systemd.services.openrgb-apply = {
    description = "Pin RGB lighting to the theme colour (#${theme.rgb})";
    after = [ "openrgb.service" ];
    requires = [ "openrgb.service" ];
    wantedBy = [ "multi-user.target" ];

    # `sleep` and `grep` are not bash builtins, and a systemd unit gets
    # no login PATH.
    path = [ pkgs.coreutils pkgs.gnugrep ];

    serviceConfig = {
      Type = "oneshot";

      # Nothing to keep running — the colour lives in the controller
      # once written. RemainAfterExit is what stops systemd reporting
      # the unit as dead-and-failed the moment it succeeds.
      RemainAfterExit = true;

      ExecStart = pkgs.writeShellScript "openrgb-apply" ''
        set -u
        openrgb=${lib.getExe config.services.hardware.openrgb.package}
        client="--client 127.0.0.1:${toString config.services.hardware.openrgb.server.port}"

        # Wait for detection to *settle*, not merely to start.
        #
        # openrgb --server binds its port before it has finished
        # enumerating, and answers a client the whole time it is still
        # working — so an early client gets a partial device list, quietly
        # colours only what has appeared so far, and exits 0. The symptom
        # is the SMBus DRAM getting set while the USB motherboard
        # controller stays on whatever the UEFI left it on, because HID
        # enumeration finishes last.
        #
        # There is no readiness signal to wait on, so poll the count and
        # require it to hold steady before trusting it.
        prev=""
        stable=0
        for _ in {1..90}; do
          count=$("$openrgb" $client --list-devices 2>/dev/null | grep -c "^[0-9]\+: ")
          if [ "$count" != 0 ] && [ "$count" = "$prev" ]; then
            stable=$((stable + 1))
            [ "$stable" -ge 3 ] && break
          else
            stable=0
          fi
          prev="$count"
          sleep 1
        done

        # Give the ARGB headers a length before colouring anything.
        #
        # JRAINBOW1/JRAINBOW2 are where the case fans are, and they come
        # up as zero-length zones — OpenRGB cannot probe how many LEDs sit
        # on an addressable strip, and a zone with no LEDs is skipped in
        # silence. That is why the fans kept running their own built-in
        # cycle while the DIMMs and the board went orange.
        #
        # Size 1, not the LED count: this board only reports zone-based
        # direct control (leds_max is 1 on these headers, and the
        # controller exposes no Direct mode at all), so the header takes a
        # single colour for the whole strip rather than per-LED data.
        # Anything above 1 is rejected as out of range.
        #
        # The board is matched by name because the device index shifts
        # with detection order — it moves if the SMBus DRAM controllers
        # fail to probe. Zone indices are fixed by the driver's zone table.
        for zone in 2 3; do # JRAINBOW1, JRAINBOW2
          "$openrgb" $client -d "B650M" -z "$zone" -sz 1 -c ${theme.rgb}
        done

        # Static is a hardware mode on all three controllers here: the
        # device latches the colour itself, so it holds with the daemon
        # stopped and comes back correct after a reboot.
        #
        # Do NOT chain fallback modes on `||`. The CLI exits 0 even when
        # it rejects a mode outright, so a chain runs every branch and the
        # last one silently wins.
        exec "$openrgb" $client --mode static --color ${theme.rgb}
      '';
    };
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
