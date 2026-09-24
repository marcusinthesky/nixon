# Development bootstrap — deliberately almost empty.
#
# Language toolchains, language servers, formatters, and linters belong to
# the repository that uses them: its devenv.nix (preferred) or flake.nix
# devShell, entered automatically by direnv. That is what pins a project's
# tools in its own lockfile rather than in whatever this host last switched
# to — and what keeps them off a laptop that is not working on that project.
#
# The host carries only what it takes to enter those environments, plus the
# two runtimes wanted for throwaway scripts outside any repository.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Project environments — `devenv init`, then `use devenv` in .envrc.
    devenv

    # Ad hoc scripting outside a repository.
    python3
    uv
    bun

    # Task runner. Every repository drives its gates through a justfile, and
    # it is needed before a shell exists to provide one.
    just
  ];
}
