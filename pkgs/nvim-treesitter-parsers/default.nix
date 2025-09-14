{
  lib,
  stdenv,
  tree-sitter-grammars,
  ...
}:
let
  inherit (builtins) toString map;
  inherit (lib) concatStringsSep;

  genTreeSitterParsersAttrs =
    parsers:
    map (parser: {
      name = parser;
      store = toString tree-sitter-grammars."tree-sitter-${parser}";
    }) parsers;

  genTreeSitterLinks =
    parsersAttrs:
    map (v: ''
      ln -svf ${v.store}/parser $out/parser/${v.name}.so
      ln -svf ${v.store}/queries/* $out/queries/${v.name}/
    '') parsersAttrs;

  nvim-treesitter-parsers = parsers: stdenv.mkDerivation {
    name = "nvim-treesitter-parsers";
    buildCommand = ''
      mkdir -p $out/{parser,queries/{${concatStringsSep "," parsers}}}
    ''
    + (parsers |> genTreeSitterParsersAttrs |> genTreeSitterLinks |> (concatStringsSep "\n"));
  };
in
nvim-treesitter-parsers
