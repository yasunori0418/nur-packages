{
  pkgs,
}:
with pkgs;
neovim-unwrapped.overrideAttrs {
  version = "0.12.0-dev";
  src = fetchFromGitHub {
    owner = "neovim";
    repo = "neovim";
    rev = "c12701d4e1404a67fef6da01a8a9d7e2d48d78d6"; # 2025-08-17T21:20:00+09:00 nightly
    hash = "sha256-n/DCESlXGFQSKF8u+tv99kW67PZgj5LSa+UGN9kOiw4=";
  };
}
