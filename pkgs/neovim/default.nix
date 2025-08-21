{
  pkgs,
  sources,
}:
with pkgs;
neovim-unwrapped.overrideAttrs {
  version = "0.12.0-dev";
  inherit (sources.neovim) src;
}
