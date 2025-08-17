{
  pkgs,
}:
let
  inherit (pkgs) lib;
  optional =
    env:
    let
      f = v: lib.optionals env v;
    in
    f;
  optionalIsLinux = optional pkgs.stdenv.isLinux;
in
with pkgs;
vim.overrideAttrs (prev: rec {
  version = "9.1.1634";
  src = fetchFromGitHub {
    owner = "vim";
    repo = "vim";
    rev = "v${version}";
    hash = "sha256-PRTvJ7DwdPE8pl2/12iTqaXUB4Jmnr8xqrHIaXbt3nQ=";
  };
  configureFlags =
    prev.configureFlags
    ++ [
      "--enable-fail-if-missing"
      "--enable-autoservername"
      "--with-features=huge"

      # if_lua
      "--enable-luainterp"
      "--with-lua-prefix=${lua}"

      # if_python3
      "--enable-python3interp=yes"
      "--with-python3-command=${python3}/bin/python3"
      "--with-python3-config-dir=${python3}/lib"
      # Disable python2
      "--disable-pythoninterp"

      # if_ruby
      "--with-ruby-command=${ruby}/bin/ruby"
      "--enable-rubyinterp"

      # if_cscope
      "--enable-cscope"

      # clipboard
      "--enable-clipboard=yes"
      "--enable-multibyte"
    ]
    ++ (optionalIsLinux [
      "--enable-gui=auto"
      "--enable-fontset"
      "--with-x"
      # お試しで有効にしたけど上手く有効化できてないシリーズ
      "--enable-xim"
      "--enable-xterm_save"
    ]);
  buildInputs =
    prev.buildInputs
    ++ [
      lua
      python3
      ruby
      libsodium
    ]
    ++ (optionalIsLinux [
      xorg.libX11
      xorg.libXt
    ]);
})
