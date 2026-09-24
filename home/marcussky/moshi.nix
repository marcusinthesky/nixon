# Moshi — phone-side remote control for local coding agents.
#
# Upstream's path is `curl -fsSL https://getmoshi.app/install.sh | sh` followed
# by `moshi-hook service install`. Neither half suits this host: the script
# drops an unmanaged binary in ~/.local/bin, and the unit it writes hardcodes
# `Environment=PATH=/usr/local/bin:/usr/bin:/bin`, which resolves none of the
# agent CLIs on a NixOS machine. Both halves are declared here instead — the
# package in nix/packages/moshi-hook.nix, the service below — so the daemon
# sees exactly the tools this profile installs.
#
# Transport is the existing tailnet: the Moshi client reaches this host over
# SSH (already scoped to tailscale0 in modules/nixos/networking.nix), and the
# daemon's own gateway binds 127.0.0.1 only. No new inbound ports.
#
# One imperative step remains, and deliberately so — pairing mints a
# host-scoped secret that must not live in the store or in Git:
#
#   moshi-hook host setup     # Easy Pair QR: SSH key + daemon secret
#   moshi-hook install        # write hook configs for the agents above
#   systemctl --user restart moshi-hook
#
# Do NOT run `moshi-hook service install`. It writes a plain file to
# ~/.config/systemd/user/moshi-hook.service, silently replacing the symlink
# Home Manager puts there, and the daemon then runs with upstream's
# unusable PATH. If it has already run: `moshi-hook service uninstall`,
# then re-activate this profile.
{ pkgs, pkgs-unstable, lib, ... }:

let
  moshi-hook = import ../../nix/packages/moshi-hook.nix { inherit pkgs; };
  herdr = import ../../nix/packages/herdr.nix { inherit pkgs; };

  # A systemd user unit inherits none of the login shell's PATH, and the daemon
  # shells out constantly — to the multiplexer for pane capture, to git for the
  # diff viewer, and to each hooked agent CLI. Spell the closure out.
  daemonPath = lib.makeBinPath [
    moshi-hook
    pkgs.tmux
    pkgs.zellij
    pkgs.git
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.procps
    herdr
    pkgs-unstable.claude-code
    pkgs-unstable.codex
    pkgs-unstable.opencode
  ];
in
{
  home.packages = [
    moshi-hook

    # `moshi <dir>` execs `tmux new-session -A -s <basename>`, and the daemon's
    # pane capture is tmux-only. The `mux = "zellij"` alias in shell.nix does
    # not satisfy either, so tmux is a hard dependency of this module rather
    # than a second-choice multiplexer in core.nix.
    pkgs.tmux
  ];

  # The daemon binds $XDG_RUNTIME_DIR/moshi-hook.sock, falling back to
  # /tmp/moshi-hook.sock when that variable is unset. A Tailscale SSH session
  # does not go through pam_systemd, so it arrives without XDG_RUNTIME_DIR —
  # the CLI and every agent hook launched from such a shell then look in /tmp,
  # find nothing, and report "daemon not running" while it is running fine.
  # Pin both ends to the same path so the two agree either way.
  home.sessionVariables.MOSHI_SOCKET_PATH = "/run/user/$UID/moshi-hook.sock";

  systemd.user.services.moshi-hook = {
    Unit = {
      Description = "Moshi hook daemon";
      Documentation = "https://getmoshi.app";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      ExecStart = "${moshi-hook}/bin/moshi-hook serve";

      Environment = [
        "PATH=${daemonPath}"

        # herdr is discovered from PATH, falling back to /usr/local/bin/herdr
        # and /opt/local/bin/herdr — neither of which exists here. Pin it.
        "MOSHI_HERDR_PATH=${herdr}/bin/herdr"

        # %t is the user manager's XDG_RUNTIME_DIR; this is the path the
        # daemon would pick anyway, restated so it matches the session
        # variable above rather than depending on how the client was invoked.
        "MOSHI_SOCKET_PATH=%t/moshi-hook.sock"
      ];

      # Unpaired, the daemon degrades to socket-only rather than exiting, so a
      # restart loop before `host setup` is not a concern.
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
