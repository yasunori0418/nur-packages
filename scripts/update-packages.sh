#!/usr/bin/env bash
# パッケージ更新スクリプト:
#   1) nvfetcher で src/version/sha256 を並列更新
#   2) 更新されたソースに対応するパッケージだけ派生固有 hash
#      (vendorHash / npmDepsHash / pnpmDeps.hash) を nix-update で再計算
#   3) treefmt でフォーマット
#   4) 差分を表示 (コミットは手動)
#
# `nix run .#update-packages` から呼ばれる想定。nvfetcher / nix-update / nix /
# jq は呼び出し元の PATH に揃っていることを前提とする (flake の app 側で注入)。
set -euo pipefail

# リポジトリルートを特定 (git 前提)
if ! ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    echo "ERROR: git リポジトリ内で実行してください" >&2
    exit 1
fi
cd "$ROOT"

SOURCES_JSON="_sources/generated.json"

# vendorHash / npmDepsHash / pnpmDeps.hash を持つパッケージ。pkgs 追加時はここを更新する。
#
# キーは _sources/generated.json のソース名、値は nix-update に渡す
# flake の attribute 名。現状は 1:1 で一致しているが、両者がズレる
# パッケージを追加したときはここで対応付けを表現する。
declare -A HASH_PKGS=(
    [k1Low-deck]=k1Low-deck
    [cchook]=cchook
    [secretlint]=secretlint
    [roots]=roots
    [laminate]=laminate
    [safe-chain]=safe-chain
)

# ソース名 → version の一覧を出力する。nvfetcher 実行前後で比較して
# 「実際に更新されたソース」だけを特定するために使う。
# generated.json が無い (初回) 場合は空を返す。
snapshot_versions() {
    if [ -f "$SOURCES_JSON" ]; then
        jq -r 'to_entries | .[] | "\(.key)\t\(.value.version)"' "$SOURCES_JSON"
    fi
}

echo "=== 1/3: nvfetcher で _sources を更新 ==="
before="$(snapshot_versions)"
nvfetcher
after="$(snapshot_versions)"

# version が変化した (= 追加または更新された) ソース名を抽出する。
# comm で before 側にしか無い行を捨て、after 側の差分行からキーを取る。
# 削除されたソースは after に現れないため自然に対象外になる。
changed_sources="$(
    comm -13 <(printf '%s\n' "$before" | sort) <(printf '%s\n' "$after" | sort) |
        cut -f1 | sort -u
)"

# 更新されたソースのうち、hash 再計算が必要なパッケージだけに絞る。
# nvfetcher が触っていないパッケージは src が変わっておらず、
# vendorHash 等も変わらないので再計算する必要がない。
targets=()
while read -r src; do
    [ -n "$src" ] || continue
    attr="${HASH_PKGS[$src]:-}"
    if [ -n "$attr" ]; then
        targets+=("$attr")
    fi
done <<<"$changed_sources"

echo
echo "=== 2/3: 更新されたパッケージの派生固有 hash を再計算 ==="
if [ "${#targets[@]}" -eq 0 ]; then
    echo "hash 再計算が必要な更新はありません (スキップ)"
    if [ -n "$changed_sources" ]; then
        echo "更新はあったが hash を持たないソース:"
        while read -r src; do
            [ -n "$src" ] || continue
            echo "  - $src"
        done <<<"$changed_sources"
    fi
fi

failed=()
for pkg in "${targets[@]:-}"; do
    [ -n "$pkg" ] || continue
    echo "--- $pkg ---"
    if ! nix-update --flake --version=skip "$pkg"; then
        echo "WARN: $pkg の hash 更新に失敗" >&2
        failed+=("$pkg")
    fi
done

echo
echo "=== 3/3: nix fmt ==="
nix fmt

echo
echo "=== 差分サマリ ==="
git --no-pager diff --stat
echo
if [ "${#failed[@]}" -gt 0 ]; then
    echo "WARN: 以下のパッケージで nix-update が失敗しました。手動で確認してください:" >&2
    printf '  - %s\n' "${failed[@]}" >&2
fi
echo "内容を確認して 'git diff' で精査し、問題なければ手動でコミットしてください。"
