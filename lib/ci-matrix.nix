pkgs:
let
  inherit (pkgs.lib)
    any
    attrNames
    filter
    genAttrs
    ;
in
rec {
  /**
    パッケージ集合から、各パッケージの全出力の narinfo ハッシュ
    （ストアパス basename の先頭 32 文字）を求める関数。

    ストアパスは `/nix/store/<32文字ハッシュ>-<name>` の形式で、cachix の
    narinfo はこのハッシュで `<hash>.narinfo` として公開される。
    unsafeDiscardStringContext で string-context を捨てるため、結果を
    文字列として扱ってもパッケージのビルドを誘発しない。

    # Example

    ```nix
    narinfoHashes {
      foo = {
        outputs = [ "out" ];
        out.outPath = "/nix/store/ph9dlvyzv1jfal5mm91ggxpk9gba4p56-foo";
      };
    }
    => { foo = [ "ph9dlvyzv1jfal5mm91ggxpk9gba4p56" ]; }
    ```

    # Type

    ```
    narinfoHashes :: AttrSet Derivation -> AttrSet [String]
    ```

    # Arguments

    packages
    : パッケージ名 -> derivation の集合。各 derivation の `outputs`（出力名の
      リスト）と各出力の `outPath` を参照する。
  */
  narinfoHashes =
    packages:
    builtins.mapAttrs (
      _: p:
      map (
        o: builtins.substring 0 32 (baseNameOf (builtins.unsafeDiscardStringContext p.${o}.outPath))
      ) p.outputs
    ) packages;

  /**
    narinfo の取得結果（純粋なデータ）から、ビルドが必要なパッケージの
    GitHub Actions matrix フラグメントを返す純粋関数。

    パッケージは「全出力ストアパスのうち1つでもキャッシュ未登録（narinfo なし）」
    のときにビルド対象として選ばれる。ネットワーク I/O（curl）は呼び出し側が
    行い、その結果 `presentHashes` を引数として受け取るため、この関数自体は
    純粋であり nix-unit でテストできる。

    # Example

    ```nix
    computeFragment {
      narinfoHashes = { a = [ "h1" ]; b = [ "h2" "h3" ]; };
      presentHashes = [ "h1" "h2" ];   # h3 が無い → b を選択
      system = "x86_64-linux";
      os = "ubuntu-latest";
    }
    => [ { package = "b"; system = "x86_64-linux"; os = "ubuntu-latest"; } ]
    ```

    # Type

    ```
    computeFragment :: {
      narinfoHashes :: AttrSet [String];
      presentHashes :: [String];
      system :: String;
      os :: String;
    } -> [AttrSet]
    ```

    # Arguments

    narinfoHashes
    : パッケージ名 -> その全出力の narinfo ハッシュ（ストアパス先頭32文字）

    presentHashes
    : キャッシュに存在が確認できた narinfo ハッシュの一覧

    system
    : 生成するエントリの system

    os
    : 生成するエントリの os（GitHub Actions ランナー）
  */
  computeFragment =
    {
      narinfoHashes,
      presentHashes,
      system,
      os,
    }:
    let
      present = genAttrs presentHashes (_: true);
      needsBuild = hashes: any (h: !(present ? ${h})) hashes;
    in
    map (package: { inherit package system os; }) (
      filter (pkg: needsBuild narinfoHashes.${pkg}) (attrNames narinfoHashes)
    );

  /**
    JSON 文字列を受け取り、fromJSON でパースしてから computeFragment に委譲する
    ラッパー。shell ↔ nix の境界を「構造化データ」ではなく「JSON 文字列」にできる
    ため、shell からは JSON 文字列を1つ渡すだけで matrix フラグメントを得られる。
    computeFragment 自体は構造化データを受け取る純粋関数のまま保たれる。

    # Example

    ```nix
    computeFragmentFromJSON ''
      {"narinfoHashes":{"b":["h2","h3"]},"presentHashes":["h2"],
       "system":"x86_64-linux","os":"ubuntu-latest"}
    ''
    => [ { package = "b"; system = "x86_64-linux"; os = "ubuntu-latest"; } ]
    ```

    # Type

    ```
    computeFragmentFromJSON :: String -> [AttrSet]
    ```

    # Arguments

    json
    : computeFragment の引数（narinfoHashes/presentHashes/system/os）を
      表す JSON 文字列
  */
  computeFragmentFromJSON = json: computeFragment (builtins.fromJSON json);
}
