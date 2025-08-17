{
  description = "My personal NUR repository";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-darwin"
          "x86_64-linux"
        ] (system: f nixpkgs.legacyPackages.${system});
    in
    {
      legacyPackages = forAllSystems (
        pkgs:
        import ./default.nix {
          inherit pkgs;
        }
      );
      packages = forAllSystems (
        pkgs: pkgs.lib.filterAttrs (_: v: pkgs.lib.isDerivation v) self.legacyPackages.${pkgs.system}
      );
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nvfetcher
            cachix
            node2nix
          ];
        };
      });
    };
}
