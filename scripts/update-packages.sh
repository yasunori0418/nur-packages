#!/usr/bin/env bash
# パッケージ更新スクリプト:
#   1) nvfetcher で src/version/sha256 を並列更新
#   2) 派生固有 hash (vendorHash / npmDepsHash / pnpmDeps.hash) を nix-update で再計算
#   3) treefmt でフォーマット
#   4) 差分を表示 (コミットは手動)
#
# `nix run .#update-packages` から呼ばれる想定。nvfetcher / nix-update / nix は
# 呼び出し元の PATH に揃っていることを前提とする (flake の app 側で注入)。
set -euo pipefail

# リポジトリルートを特定 (git 前提)
if ! ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    echo "ERROR: git リポジトリ内で実行してください" >&2
    exit 1
fi
cd "$ROOT"

# vendorHash / npmDepsHash / pnpmDeps.hash を持つパッケージ。pkgs 追加時はここを更新する。
HASH_PKGS=(
    k1Low-deck
    cchook
    secretlint
    roots
    laminate
    safe-chain
)

echo "=== 1/3: nvfetcher で _sources を更新 ==="
nvfetcher

echo
echo "=== 2/3: 派生固有 hash を nix-update --version=skip で再計算 ==="
failed=()
for pkg in "${HASH_PKGS[@]}"; do
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
