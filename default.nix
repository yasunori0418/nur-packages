# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `modules` and `overlays`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage

{
  pkgs ? import <nixpkgs> { },
}:
let
  nodePkgs = pkgs.callPackage ./pkgs/node2nix {
    inherit pkgs;
    inherit (pkgs) system;
    nodejs = pkgs.nodejs_24;
  };
  sources = pkgs.callPackage ./_sources/generated.nix { };
in
{
  # The `lib`, `modules`, and `overlays` names are special
  lib = import ./lib { inherit pkgs; }; # functions
  modules = import ./modules; # NixOS modules
  overlays = import ./overlays; # nixpkgs overlays

  safe-chain = nodePkgs."@aikidosec/safe-chain";
  ccexp = nodePkgs."ccexp";
  cchook = pkgs.callPackage ./pkgs/cchook { inherit sources; };
  gwq = pkgs.callPackage ./pkgs/gwq { inherit sources; };
  k1Low-deck = pkgs.callPackage ./pkgs/k1Low-deck { inherit sources; };
  laminate = pkgs.callPackage ./pkgs/laminate { inherit sources; };
  vim = pkgs.callPackage ./pkgs/vim { inherit sources; };
  neovim = pkgs.callPackage ./pkgs/neovim { inherit sources; };
  nvim-treesitter-parsers = pkgs.callPackage ./pkgs/nvim-treesitter-parsers { };
  pict = pkgs.callPackage ./pkgs/pict { inherit sources; };
}
