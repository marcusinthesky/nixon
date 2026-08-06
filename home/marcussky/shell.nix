# Zsh — Home Manager module (user-level)
#
# Per-user aliases, session variables, and initExtra.
# System-level zsh (oh-my-zsh, plugins) is in modules/nixos/shell.nix.
_:

{
  # claude-code self-updates outside Nix into ~/.local/share/claude/versions,
  # symlinked from ~/.local/bin/claude; keep it ahead of the Nix-packaged binary.
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;

    # Aliases
    shellAliases = {
      # Keep incompatible replacements available under their native names;
      # their command-line semantics differ from the tools they replace.
      ll = "eza -la --icons --git";
      la = "eza -a --icons";
      lt = "eza --tree --icons --level=2";
      mux = "zellij";
      k = "kubectl";
      kns = "kubectl config set-context --current --namespace";
      dc = "docker compose";
      gs = "git status";
      gd = "git diff";
      gp = "git push";
      gl = "git pull";
      dirac = "bunx --package dirac-cli dirac"; # `https://github.com/dirac-run/dirac` coding agent cli
      vibe = "uvx --from mistral-vibe vibe"; # `https://mistral.ai/news/leanstral-1-5/#get-started` Mistral Vibe AI coding agent
    };

    sessionVariables = {
      EDITOR = "code --wait";
      DOCKER_BUILDKIT = "1";
    };

    initContent = ''
      # Preserve standard utility behavior for interactive users and agents.
      # NixOS/oh-my-zsh adds aliases for these names at the system layer.
      unalias ls grep egrep fgrep 2>/dev/null || true

      # Load completions
      autoload -Uz compinit && compinit
    '';
  };
}
