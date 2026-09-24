# moshi-hook — Moshi's agent-hook daemon and CLI.
#
# Upstream ships no public Git repository and no GitHub release mirror; the
# versioned CDN path is the only fetchable artefact, so the URL is pinned by
# version and the hash is the one published in that release's checksums.txt.
# Verify a bump before changing the hash:
#
#   curl -fsSL https://cdn.getmoshi.app/hook/latest/version.txt
#   curl -fsSL https://cdn.getmoshi.app/hook/v<X.Y.Z>/checksums.txt
#
# The upstream installer also exposes `moshi` as an alias for `moshi-hook`;
# the symlink below reproduces that without running a curl|sh script.
{ pkgs }:

pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "moshi-hook";
  version = "0.2.75";

  src = pkgs.fetchurl {
    url = "https://cdn.getmoshi.app/hook/v${finalAttrs.version}/moshi-hook_Linux_x86_64.tar.gz";
    hash = "sha256-ebZ1PxMzcP2vFDxCPEnQ6FTp0GJ8TlEGty42VrOsU5A=";
  };

  # The archive has no top-level directory: README.md, docs/, moshi-hook.
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    install -Dm755 moshi-hook $out/bin/moshi-hook
    ln -s moshi-hook $out/bin/moshi

    install -Dm644 README.md -t $out/share/doc/moshi-hook
    install -Dm644 docs/*.md -t $out/share/doc/moshi-hook

    runHook postInstall
  '';

  # Statically linked Go binary — no interpreter or RPATH to patch.
  dontPatchELF = true;
  dontStrip = true;

  meta = {
    description = "Agent-hook daemon and CLI for Moshi remote agent control";
    longDescription = ''
      Bridges local coding agents (Claude Code, Codex, OpenCode, …) to the
      Moshi phone client over a WebSocket, publishing session state and
      relaying permission approvals. `moshi <dir>` additionally attaches a
      per-project tmux session.

      `moshi-hook update` is inert here: the store path is read-only, so
      upgrades happen by bumping `version` and `hash` in this file.
    '';
    homepage = "https://getmoshi.app";
    mainProgram = "moshi-hook";
    platforms = [ "x86_64-linux" ];
  };
})
