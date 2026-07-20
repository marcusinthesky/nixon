# Opt-in hardware and low-level diagnostics.
#
# These remain separate from the default profile because they are specialist
# tools: strace/lsof for debugging, VA-API/GPU tools for media diagnostics,
# and lm_sensors for hardware telemetry.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    htop
    lsof
    strace
    libva-utils
    intel-gpu-tools
    lm_sensors
  ];
}
