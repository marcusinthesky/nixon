# herdr — agentic coding workspace.
# Kept separate from Home Manager so custom package definitions have one home.
{ pkgs }:

pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "herdr";
  version = "0.7.5";

  src = pkgs.fetchurl {
    url = "https://github.com/herdrdev/herdr/releases/download/v${finalAttrs.version}/herdr-linux-x86_64";
    hash = "sha256-PcgyiAc+TC08Z5ow576XvMqRQcb9F9u7khkULpXFklM=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/herdr
    runHook postInstall
  '';

  meta = {
    description = "Agentic coding workspace";
    homepage = "https://herdr.dev";
    mainProgram = "herdr";
    platforms = [ "x86_64-linux" ];
  };
})
