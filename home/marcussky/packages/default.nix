# Home Manager package profiles.
#
# The default switch includes only the profiles below. Larger specialist stacks
# remain available as explicit imports when they are needed:
#   ./kubernetes.nix, ./media.nix, ./diagnostics.nix
{ ... }:

{
  imports = [
    ./core.nix
    ./development.nix
    ./agents.nix
  ];
}
