{
  symlinkJoin,
  vimPlugins,
  ...
}:
let
  # queries は parser と同一 nixpkgs スナップショットの nvim-treesitter 本体から
  # 供給する。parser rev とクエリの整合が nixpkgs 側で保証されるため、
  # 別経路(プラグインマネージャの HEAD 追従)由来のクエリとの node type 不一致を防ぐ。
  nvim-treesitter-parsers =
    parsers:
    symlinkJoin {
      name = "nvim-treesitter-parsers";
      paths = map (parser: vimPlugins.nvim-treesitter-parsers.${parser}) parsers;
      postBuild = ''
        ln -s ${vimPlugins.nvim-treesitter}/runtime/queries $out/queries
      '';
    };
in
nvim-treesitter-parsers
