# Opt-in hardware and low-level diagnostics.
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
