# Opt-in media and creative applications.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gimp
    inkscape
    audacity
    obs-studio
    handbrake
    ffmpeg
  ];
}
