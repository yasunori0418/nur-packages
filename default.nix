# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `modules` and `overlays`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage

{
  pkgs ? import <nixpkgs> { },
  inputs,
}:
let
  sources = pkgs.callPackage ./_sources/generated.nix { };
  inherit (pkgs.stdenv.hostPlatform) system;
  inheritSources = { inherit sources; };
in
{
  # The `lib`, `modules`, and `overlays` names are special
  lib = import ./lib/default.nix { inherit pkgs; }; # functions
  modules = import ./modules/default.nix; # NixOS modules
  overlays = import ./overlays/default.nix; # nixpkgs overlays

  safe-chain = pkgs.callPackage ./pkgs/safe-chain/default.nix inheritSources;
  cchook = pkgs.callPackage ./pkgs/cchook/default.nix inheritSources;
  k1Low-deck = pkgs.callPackage ./pkgs/k1Low-deck/default.nix inheritSources;
  laminate = pkgs.callPackage ./pkgs/laminate/default.nix inheritSources;
  # vim = pkgs.callPackage ./pkgs/vim/default.nix inheritSources;
  vim-overlay =
    (pkgs.extend (
      inputs.vim-overlay.lib.features {
        cscope = true;
        lua = true;
        python3 = true;
        ruby = true;
        sodium = true;
      }
    )).vim;
  # neovim = pkgs.callPackage ./pkgs/neovim/default.nix inheritSources;
  pict = pkgs.callPackage ./pkgs/pict/default.nix inheritSources;
  kotlin-lsp = pkgs.callPackage ./pkgs/kotlin-lsp/default.nix { };
  # Linux専用。nullはlib.isDerivationフィルタで除外される
  xremap-wlroots =
    if pkgs.stdenv.isLinux then inputs.xremap-flake.packages.${system}.xremap-wlroots else null;
  roots = pkgs.callPackage ./pkgs/roots/default.nix inheritSources;
  secretlint = pkgs.callPackage ./pkgs/secretlint/default.nix inheritSources;
  worktrunk = inputs.worktrunk.packages.${system}.default;
  deno = pkgs.callPackage ./pkgs/deno-overlay/default.nix inheritSources;
}
