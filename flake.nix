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
    vim-overlay.url = "github:kawarimidoll/vim-overlay";
    xremap-flake.url = "github:xremap/nix-flake";
    rust-overlay.url = "github:oxalica/rust-overlay";
    worktrunk = {
      url = "github:max-sixty/worktrunk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };
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
          "x86_64-linux"
        ] (system: f nixpkgs.legacyPackages.${system});
      treefmtEval = forAllSystems (pkgs: inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
      nixUnitFor = pkgs: inputs.nix-unit.packages.${pkgs.stdenv.hostPlatform.system}.default;

      # narinfo が未登録のパッケージだけを含む matrix フラグメント
      # （[{package,system,os}]）を stdout に出力する app。
      # ログは stderr に出すため stdout は JSON のみ。
      # 使い方: ci-matrix <os>   （system は app がビルドされた環境に固定）
      #
      # 役割分担:
      #   - 不純なネットワーク I/O（各 narinfo の有無を curl で確認）だけを shell が担当。
      #   - 「どのパッケージをビルド対象にするか」「matrix エントリの生成」という
      #     判定ロジックは lib.ci-matrix.computeFragment（純粋関数・nix-unit で
      #     テスト可能）に委譲する。curl の結果を引数として渡すことで関数を純粋に保つ。
      #
      # narinfoHashes は「この app が動く system（= ネイティブ）」の self.packages
      # だけを純粋に評価して baked する。foreign system を評価しないため他
      # アーキテクチャの IFD（apple-sdk/llvm 等）を誘発せず、エミュレーションに
      # よる長時間化が起きない。各 plan ジョブはネイティブランナーで動くので
      # baked される system はランナーの system と一致する。
      # unsafeDiscardStringContext で string-context を捨て、app のビルドが
      # 全パッケージのビルドを誘発しないようにする。
      ciMatrixApp =
        pkgs:
        let
          system = pkgs.stdenv.hostPlatform.system;
          ciLib = import ./lib/ci-matrix.nix pkgs;
          # narinfo ハッシュ（= ストアパス basename の先頭 32 文字）を lib 関数で算出。
          narinfoHashes = ciLib.narinfoHashes self.packages.${system};
        in
        pkgs.writeShellApplication {
          name = "ci-matrix";
          runtimeInputs = with pkgs; [
            jq
            curl
          ];
          # jq フィルタは単一引用符で囲うためシェル変数展開させない意図。
          # SC2016 はその誤検知なので除外する。
          excludeShellChecks = [ "SC2016" ];
          text = ''
            set -euo pipefail
            os="''${1:?usage: ci-matrix <os>}"
            system='${system}'
            cache="''${CACHIX_CACHE:-yasunori0418}"
            hashes='${builtins.toJSON narinfoHashes}'
            # 不純なネットワーク I/O のみ shell が担当：
            # 全ユニークハッシュについて narinfo の有無を確認する。
            present=()
            while read -r hash; do
              code="$(curl -s -o /dev/null -w '%{http_code}' \
                "https://''${cache}.cachix.org/''${hash}.narinfo")"
              if [ "$code" = "200" ]; then
                present+=("$hash")
              else
                echo "missing $hash" >&2
              fi
            done < <(jq -r '[.[][]] | unique | .[]' <<<"$hashes")
            present_json="$(printf '%s\n' "''${present[@]:-}" \
              | jq -R -s 'split("\n") | map(select(length > 0))')"
            # 判定・matrix 生成は lib の純粋関数に委譲。curl 結果を含む入力を
            # JSON 文字列にし、JSON 文字列を受け取る computeFragmentFromJSON へ渡す。
            payload="$(jq -c -n \
              --argjson narinfoHashes "$hashes" \
              --argjson presentHashes "$present_json" \
              --arg system "$system" \
              --arg os "$os" \
              '{ narinfoHashes: $narinfoHashes, presentHashes: $presentHashes, system: $system, os: $os }')"
            # 判定は flake の lib 属性を参照して評価する。flake 属性アクセスは
            # pure 評価で許可されるため --impure 不要で、pkgs も flake 側が供給する。
            # 三連シングルクォートは nix 複数行文字列中で 2連シングルクォートを
            # 出力するエスケープで、生成シェルでは payload を nix 文字列として渡す。
            nix eval --json \
              "${self}#legacyPackages.${system}.lib.ci-matrix.computeFragmentFromJSON" \
              --apply "f: f '''$payload'''"
          '';
        };

      # nvfetcher → nix-update → nix fmt を一括で回すローカル更新スクリプト。
      # 実体は scripts/update-packages.sh に置き、この app は runtimeInputs で
      # nvfetcher/nix-update を PATH に揃えたうえでスクリプトを exec する薄いラッパー。
      updatePackagesApp =
        pkgs:
        pkgs.writeShellApplication {
          name = "update-packages";
          runtimeInputs = with pkgs; [
            nvfetcher
            nix-update
            git
            nix
          ];
          text = ''
            set -euo pipefail
            if ! root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
              echo "ERROR: git リポジトリ内で実行してください" >&2
              exit 1
            fi
            exec bash "$root/scripts/update-packages.sh" "$@"
          '';
        };
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
              nix-unit = nixUnitFor pkgs;
            in
            with pkgs;
            [
              nvfetcher
              nix-update
              cachix
              nix-unit
            ];
        };
      });
      apps = forAllSystems (pkgs: {
        ci-matrix = {
          type = "app";
          program = "${ciMatrixApp pkgs}/bin/ci-matrix";
          meta.description = "Emit a GitHub Actions build matrix, skipping packages already on the cachix cache";
        };
        update-packages = {
          type = "app";
          program = "${updatePackagesApp pkgs}/bin/update-packages";
          meta.description = "Run nvfetcher then nix-update --version=skip for all packages with vendor/npm/pnpm hashes";
        };
      });
      formatter = forAllSystems (
        pkgs: treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper
      );
      checks = forAllSystems (pkgs: {
        default =
          let
            nix-unit = nixUnitFor pkgs;
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
