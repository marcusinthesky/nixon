# Zsh — Home Manager module (user-level)
#
# Per-user aliases, session variables, and initExtra.
# System-level zsh (oh-my-zsh, plugins) is in modules/nixos/shell.nix.
_:

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;

    # Aliases
    shellAliases = {
      ll = "eza -la --icons --git";
      la = "eza -a --icons";
      lt = "eza --tree --icons --level=2";
      cat = "bat";
      du = "dust";
      ps = "procs";
      top = "btm";
      sed = "sd";
      ping = "gping";
      tar = "ouch";
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
      # Load completions
      autoload -Uz compinit && compinit
    '';
  };
}
