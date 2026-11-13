# One spot for your own flake packages (see ../pkgs): an active `callPackage`
# line installs it once it is referenced from common/apps.nix; everything else
# stays commented out to be reactivated later. No active entries at the moment:
# Double Commander comes from nixpkgs itself (common/apps.nix).
#
# Two entries drew their source from flake inputs that were removed from
# flake.nix together with them: hylki (input hylki-src, passed as
# `src = inputs.hylki-src;`) and revpdf (input revpdf-release, passed as
# `inherit (inputs) revpdf-release;`). Reactivating one of them means adding
# the input back and changing this line back to:
#     { inputs }: final: _prev: { ... }
#
# Deadnix: with no active entry both parameters are unused (`_final`, `_prev`).
# When uncommenting a line, change `_final` back to `final` — most entries use it.
_final: _prev: {
  # Reactivate when needed (see above for flake input sources):
  # bibox = final.callPackage ./bibox/package.nix { };
  # cornelsen-offline-lernen = final.callPackage ./cornelsen-offline-lernen/package.nix { };
  # doublecmd-qt6 = final.callPackage ./doublecmd-qt6/package.nix { };
  # Replaces nixpkgs' flaci (older, no desktop entry), see the package.
  # flaci = final.callPackage ./flaci/package.nix { };
  # hylki = final.callPackage ./hylki/package.nix { src = inputs.hylki-src; };
  # Logseq: nixpkgs pins it to Electron 39, which is EOL and now refused by Nix;
  # use the first non-EOL Electron (42) instead.
  # logseq = _prev.logseq.override { electron_39 = final.electron_42; };
  # mtplayer = final.callPackage ./mtplayer/package.nix { };
  # revpdf = final.callPackage ./revpdf/package.nix { inherit (inputs) revpdf-release; };
}
