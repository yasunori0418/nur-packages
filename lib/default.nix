{ pkgs, ... }:
{
  # Add your library functions here
  #
  # hexint = x: hexvals.${toLower x};
  attrsets = import ./attrsets.nix pkgs; 
}
