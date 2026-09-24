# Git — Home Manager module
#
# User-level git config: identity, delta pager, useful aliases.
_:

{
  programs = {
    git = {
      enable = true;
      lfs.enable = true;

      settings = {
        user = {
          name = "Marcus Gawronsky";
          email = ""; # TODO: set your email
        };
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        core.editor = "zeditor --wait";
        alias = {
          co = "checkout";
          br = "branch";
          ci = "commit";
          st = "status";
          lg = "log --oneline --graph --decorate --all";
        };
      };
    };

    # delta — beautiful diffs in the terminal
    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
      };
    };

    # GitHub CLI
    gh = {
      enable = true;
      settings.git_protocol = "ssh";
    };
  };
}
