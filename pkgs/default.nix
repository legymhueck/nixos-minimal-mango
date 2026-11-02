# One spot for your own flake packages (see ../pkgs): an active `callPackage`
# line installs it once it is referenced from common/apps.nix; everything else
# stays commented out to be reactivated later.
#
# hylki and revpdf draw their source from flake inputs (`hylki-src`,
# `revpdf-release`; both declared in flake.nix). Removing one of them from the
# system means also removing its input (and the `inputs` argument here once no
# entry uses it).
{ inputs }: final: _prev: {
  # Reactivate when needed (see above for flake input sources):
  # bibox = final.callPackage ./bibox/package.nix { };
  # cornelsen-offline-lernen = final.callPackage ./cornelsen-offline-lernen/package.nix { };
  # doublecmd-qt6 = final.callPackage ./doublecmd-qt6/package.nix { };
  # Replaces nixpkgs' flaci (older, no desktop entry), see the package.
  # flaci = final.callPackage ./flaci/package.nix { };
  hylki = final.callPackage ./hylki/package.nix { src = inputs.hylki-src; };
  # Logseq: nixpkgs pins it to Electron 39, which is EOL and now refused by Nix;
  # use the first non-EOL Electron (42) instead.
  # logseq = _prev.logseq.override { electron_39 = final.electron_42; };
  # mtplayer = final.callPackage ./mtplayer/package.nix { };
  revpdf = final.callPackage ./revpdf/package.nix { inherit (inputs) revpdf-release; };
}
