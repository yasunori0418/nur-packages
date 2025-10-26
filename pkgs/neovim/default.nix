{
  pkgs,
  sources,
}:
with pkgs;
let
  tree-sitter-updated = tree-sitter.overrideAttrs (old: {
    inherit (sources.tree-sitter) pname version src;
  });
in
neovim-unwrapped.overrideAttrs (prev: {
  version = "0.12.0-dev";
  inherit (sources.neovim) src;

  buildInputs = map (
    dep: if (dep.pname or "") == "tree-sitter" then tree-sitter-updated else dep
  ) prev.buildInputs;
})
