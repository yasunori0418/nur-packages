{
  pkgs ? import <nixpkgs> { },
  ...
}:
let
  lib = import ./ci-matrix.nix pkgs;
  base = {
    narinfoHashes = {
      a = [ "h1" ];
      b = [
        "h2"
        "h3"
      ];
    };
    system = "x86_64-linux";
    os = "ubuntu-latest";
  };
in
{
  computeFragment = {
    testAllCached = {
      description = "全出力がキャッシュ済みなら空リストを返す";
      expr = lib.computeFragment (
        base
        // {
          presentHashes = [
            "h1"
            "h2"
            "h3"
          ];
        }
      );
      expected = [ ];
    };
    testPartialMissing = {
      description = "出力の1つでも欠ければそのパッケージを選ぶ";
      expr = lib.computeFragment (
        base
        // {
          presentHashes = [
            "h1"
            "h2"
          ];
        }
      );
      expected = [
        {
          package = "b";
          system = "x86_64-linux";
          os = "ubuntu-latest";
        }
      ];
    };
    testNoneCached = {
      description = "全て未登録なら全パッケージを選ぶ（attrName 昇順）";
      expr = lib.computeFragment (base // { presentHashes = [ ]; });
      expected = [
        {
          package = "a";
          system = "x86_64-linux";
          os = "ubuntu-latest";
        }
        {
          package = "b";
          system = "x86_64-linux";
          os = "ubuntu-latest";
        }
      ];
    };
  };
  computeFragmentFromJSON = {
    testParsesJsonAndDelegates = {
      description = "JSON 文字列を fromJSON して computeFragment と同じ結果を返す";
      expr = lib.computeFragmentFromJSON ''
        {"narinfoHashes":{"a":["h1"],"b":["h2","h3"]},"presentHashes":["h1","h2"],"system":"x86_64-linux","os":"ubuntu-latest"}
      '';
      expected = [
        {
          package = "b";
          system = "x86_64-linux";
          os = "ubuntu-latest";
        }
      ];
    };
  };
  narinfoHashes = {
    testSingleOutput = {
      description = "単一出力: ストアパス basename の先頭32文字をハッシュとして返す";
      expr = lib.narinfoHashes {
        foo = {
          outputs = [ "out" ];
          out.outPath = "/nix/store/ph9dlvyzv1jfal5mm91ggxpk9gba4p56-foo-1.0";
        };
      };
      expected = {
        foo = [ "ph9dlvyzv1jfal5mm91ggxpk9gba4p56" ];
      };
    };
    testMultipleOutputs = {
      description = "複数出力: outputs の順に全出力のハッシュを返す";
      expr = lib.narinfoHashes {
        bar = {
          outputs = [
            "out"
            "man"
          ];
          out.outPath = "/nix/store/srs5w2j099ijfbqqy1x8ja4b7g2kdxvw-bar";
          man.outPath = "/nix/store/1jxh6ks85vaby6axkxzk9xpg29dzqrc4-bar-man";
        };
      };
      expected = {
        bar = [
          "srs5w2j099ijfbqqy1x8ja4b7g2kdxvw"
          "1jxh6ks85vaby6axkxzk9xpg29dzqrc4"
        ];
      };
    };
    testMultiplePackages = {
      description = "複数パッケージ: パッケージ名ごとにハッシュ一覧を返す";
      expr = lib.narinfoHashes {
        a = {
          outputs = [ "out" ];
          out.outPath = "/nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-a";
        };
        b = {
          outputs = [ "out" ];
          out.outPath = "/nix/store/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb-b";
        };
      };
      expected = {
        a = [ "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" ];
        b = [ "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" ];
      };
    };
  };
}
