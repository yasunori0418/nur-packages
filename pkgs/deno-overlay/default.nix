{
  lib,
  pkgs,
  deno-overlay,
}:
let
  # deno-overlay は `deno.<version>` (例: deno."2.0.0") の形で
  # バージョンごとの derivation を生やすオーバーレイ。
  # sources.json の読み込み (IFD) は overlay 内部で行われるが、
  # flake input として lock 済みなので src は常に store 上にある。
  denoVersions = (pkgs.extend deno-overlay.overlays.deno-overlay).deno;

  # sources.json に載っている全バージョンのうち最新を採用する。
  # arch が無いバージョンは overlay 側が throw するため、
  # 評価に成功したものだけを候補にし、versionOlder で最大値へ畳み込む。
  # 初期値 "" は versionOlder "" <任意の実バージョン> が真になるので単位元として働く。
  # 候補が空なら畳み込み結果も "" のままになる。
  latestVersion = lib.pipe denoVersions [
    builtins.attrNames
    (lib.filter (v: (builtins.tryEval denoVersions.${v}).success))
    (lib.foldl' (acc: v: if lib.versionOlder acc v then v else acc) "")
  ];
in
# 現行 sources.json は aarch64-darwin / aarch64-linux / x86_64-linux を
# 網羅しているので通常このフォールバックには入らないが、上流が arch を
# 落とした場合に評価全体を壊さないよう null を返す。
# null は lib.isDerivation フィルタで packages 出力から除外される。
if latestVersion == "" then null else denoVersions.${latestVersion}
