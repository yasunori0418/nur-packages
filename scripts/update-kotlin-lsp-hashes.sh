#!/usr/bin/env bash
# kotlin-lsp の fetchurl hash 更新スクリプト:
#   pkgs/kotlin-lsp/default.nix の version に合わせて、上流が配布物ごとに
#   公開している <配布物>.sha256 を取得し、4 プラットフォーム分の hash を
#   SRI 形式に変換して書き換える。アーカイブ本体はダウンロードしない。
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
    # <配布物>.sha256 は "<hex> *<ファイル名>" 形式
    hex="$(curl -fsSL "${base}${archive}.sha256" | cut -d' ' -f1)"
    if ! [[ "$hex" =~ ^[0-9a-f]{64}$ ]]; then
        echo "ERROR: ${base}${archive}.sha256 から sha256 を取得できません" >&2
        exit 1
    fi
    sri="$(nix hash convert --hash-algo sha256 --to sri "$hex")"
    echo "$system: $sri"
    sed -i "s|^\( *${system} = \)\"sha256-[^\"]*\";|\1\"${sri}\";|" "$NIX_FILE"
    if ! grep -qF "${system} = \"${sri}\";" "$NIX_FILE"; then
        echo "ERROR: $NIX_FILE の ${system} の hash を書き換えられません" >&2
        exit 1
    fi
done

git --no-pager diff --stat -- "$NIX_FILE"
