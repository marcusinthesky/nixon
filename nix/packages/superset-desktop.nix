# Superset Desktop — agentic coding workspace.
# Kept separate from Home Manager so custom package definitions have one home.
{ pkgs }:

pkgs.appimageTools.wrapType2 {
  pname = "superset-desktop";
  version = "1.12.5";
  src = pkgs.fetchurl {
    url = "https://github.com/superset-sh/superset/releases/download/desktop-v1.12.5/superset-1.12.5-x86_64.AppImage";
    hash = "sha256-TMfY0q5AnBFUhpU62AkiXBDj1mXeRzIQyRZhiPErvNg=";
  };
}
