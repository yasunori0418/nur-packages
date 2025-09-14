{
  lib,
  stdenv,
  tree-sitter-grammars,
  ...
}:
let
  inherit (builtins) toString;
  inherit (lib) concatStringsSep foldl;

  baseOutDirectory = "mkdir -p $out/{parser,queries}";

  genQueriesDirectory = foldl (acc: parser: acc + "mkdir -p $out/queries/${parser}\n") "";

  genTreeSitterLinks = foldl (
    acc: parser:
    let
      name = parser;
      store = toString tree-sitter-grammars."tree-sitter-${parser}";
    in
    acc
    + ''
      ln -svf ${store}/parser $out/parser/${name}.so
      ln -svf ${store}/queries/* $out/queries/${name}/
    ''
  ) "";

  nvim-treesitter-parsers =
    parsers:
    stdenv.mkDerivation {
      name = "nvim-treesitter-parsers";
      buildCommand = concatStringsSep "\n" [
        baseOutDirectory
        (genQueriesDirectory parsers)
        (genTreeSitterLinks parsers)
      ];
    };
in
nvim-treesitter-parsers
