# Docker — container runtime with weekly auto-prune
{ pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_29;
    autoPrune = {
      enable = true;
      # Keep this away from Sunday Nix GC and Monday's weekly fstrim.
      dates = "Wed 03:00";
    };
  };
}
