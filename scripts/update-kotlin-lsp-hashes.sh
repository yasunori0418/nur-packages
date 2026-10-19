#!/usr/bin/env bash
# kotlin-lsp の fetchzip hash 更新スクリプト:
#   pkgs/kotlin-lsp/default.nix の version に合わせて、4 プラットフォーム分の
#   hash を nix-prefetch-url --unpack で再計算して書き換える。
#
# Renovate は version だけを更新し hash を再計算できないため、
# renovate/** ブランチの CI (.github/workflows/kotlin-lsp-hash.yml) から呼ばれる。
# ローカルで version を手で上げたときにも使える。
set -euo pipefail

if ! ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    echo "ERROR: git リポジトリ内で実行してください" >&2
    exit 1
fi
cd "$ROOT"

NIX_FILE="pkgs/kotlin-lsp/default.nix"

version="$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$NIX_FILE")"
if [ -z "$version" ]; then
    echo "ERROR: $NIX_FILE から version を取得できません" >&2
    exit 1
fi
echo "kotlin-lsp version: $version"

base="https://download.jetbrains.com/language-server/kotlin-server/${version}/kotlin-server-${version}"

# system -> 配布物の接尾辞 (default.nix の archiveInfo の suffix と ext に対応)
declare -A ARCHIVES=(
    [aarch64-darwin]="-aarch64.sit"
    [x86_64-darwin]=".sit"
    [aarch64-linux]="-aarch64.tar.gz"
    [x86_64-linux]=".tar.gz"
)

for system in "${!ARCHIVES[@]}"; do
    archive="${ARCHIVES[$system]}"
    # .sit は実体が ZIP。fetchzip の extension = "zip" と同じく展開させるため .zip 名を付ける
    name_args=()
    if [[ "$archive" == *.sit ]]; then
        name_args=(--name src.zip)
    fi
    raw="$(nix-prefetch-url --unpack --type sha256 "${name_args[@]}" "${base}${archive}")"
    sri="$(nix hash convert --hash-algo sha256 --to sri "$raw")"
    echo "$system: $sri"
    sed -i "s|^\(        ${system} = \)\"sha256-[^\"]*\";|\1\"${sri}\";|" "$NIX_FILE"
done

git --no-pager diff --stat -- "$NIX_FILE"
