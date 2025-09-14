{
  symlinkJoin,
  vimPlugins,
  ...
}:
let
  nvim-treesitter-parsers =
    parsers:
    symlinkJoin {
      name = "nvim-treesitter-parsers";
      paths = map (parser: vimPlugins.nvim-treesitter-parsers.${parser}) parsers;
    };
in
nvim-treesitter-parsers
