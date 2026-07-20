# Always-on workstation and CLI tools.
{ pkgs, toolPackages, ... }:

{
  home.packages = (with pkgs; [
    # Text, file, and shell tools
    ripgrep
    fd
    bat
    eza
    zoxide
    atuin
    tealdeer
    sd
    choose
    difftastic
    ouch
    xh
    broot
    helix
    hyperfine
    tokei
    watchexec
    jq
    yq
    zellij

    # System and networking basics
    bottom
    procs
    dust
    fastfetch
    openssh
    wget
    curl
    gping
    doggo
    rsync
    unzip
    zip

    # Keep this explicit CLI available without replacing GNU coreutils in PATH.
    uutils-coreutils

    # ImageMagick is used by the configuration for Stylix wallpaper generation.
    imagemagick

    # Browsers
    google-chrome
  ]) ++ toolPackages;
}
