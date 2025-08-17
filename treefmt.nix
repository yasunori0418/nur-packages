# treefmt.nix
{ pkgs, ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";
  programs = {
    nixfmt = {
      enable = true;
      package = pkgs.nixfmt-rfc-style;
    };
    statix = {
      enable = true;
      excludes = [
        ".direnv"
      ];
    };
  };
}
