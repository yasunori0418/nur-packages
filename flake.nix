{
  description = "My personal NUR repository";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-unit = {
      url = "github:nix-community/nix-unit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      treefmtEval = forAllSystems (pkgs: inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      legacyPackages = forAllSystems (pkgs: import ./default.nix { inherit pkgs; });
      packages = forAllSystems (
        pkgs: pkgs.lib.filterAttrs (_: v: pkgs.lib.isDerivation v) self.legacyPackages.${pkgs.system}
      );
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages =
            let
              nix-unit = inputs.nix-unit.packages.${pkgs.system}.default;
            in
            with pkgs;
            [
              nvfetcher
              cachix
              node2nix
              nix-unit
            ];
        };
      });
      formatter = forAllSystems (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
      checks = forAllSystems (pkgs: {
        default =
          let
            nix-unit = inputs.nix-unit.packages.${pkgs.system}.default;
          in
          pkgs.runCommand "tests"
            {
              nativeBuildInputs = [ nix-unit ];
            }
            ''
              export HOME="$(realpath .)"
              # The nix derivation must be able to find all used inputs in the nix-store because it cannot download it during buildTime.
              nix-unit \
                --eval-store "$HOME" \
                --extra-experimental-features flakes \
                --extra-experimental-features pipe-operators \
                --override-input nixpkgs ${nixpkgs} \
                --impure \
                --flake '${self}#tests'
              touch $out
            '';
        formatting = treefmtEval.${pkgs.system}.config.build.check self;
      });
      tests = forAllSystems (pkgs: {
        lib = import ./lib/default_test.nix { inherit pkgs; };
      });
    };
}
