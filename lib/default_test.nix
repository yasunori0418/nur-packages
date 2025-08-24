{
  pkgs ? import <nixpkgs> { },
  ...
}:
{
  attrsets = import ./attrsets_test.nix { inherit pkgs; };
}
