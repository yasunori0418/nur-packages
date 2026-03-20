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
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    vim-overlay.url = "github:kawarimidoll/vim-overlay";
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://yasunori0418.cachix.org"
    ];

    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "yasunori0418.cachix.org-1:mC1j+M5A6063OHaOB5bH2nS0BiCW/BJsSRiOWjLeV9o="
    ];
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
      legacyPackages = forAllSystems (pkgs: import ./default.nix { inherit pkgs inputs; });
      packages = forAllSystems (
        pkgs:
        pkgs.lib.filterAttrs (
          _: v: pkgs.lib.isDerivation v
        ) self.legacyPackages.${pkgs.stdenv.hostPlatform.system}
      );
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages =
            let
              nix-unit = inputs.nix-unit.packages.${pkgs.stdenv.hostPlatform.system}.default;
            in
            with pkgs;
            [
              nvfetcher
              cachix
              nix-unit
            ];
        };
      });
      formatter = forAllSystems (
        pkgs: treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper
      );
      checks = forAllSystems (pkgs: {
        default =
          let
            nix-unit = inputs.nix-unit.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
                --override-input nixpkgs ${nixpkgs} \
                --impure \
                --flake '${self}#tests'
              touch $out
            '';
        formatting = treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.check self;
      });
      tests = forAllSystems (pkgs: {
        lib = import ./lib/default_test.nix { inherit pkgs; };
      });
    };
}
