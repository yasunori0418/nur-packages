{
  pkgs ? import <nixpkgs> { },
  ...
}:
{
  attrsets = import ./attrsets_test.nix { inherit pkgs; };
  ci-matrix = import ./ci-matrix_test.nix { inherit pkgs; };
}
