# CLAUDE.md

個人用NUR（Nix User Repository）。カスタムNixパッケージ、ライブラリ関数、NixOSモジュール、オーバーレイを含む。

## ディレクトリ構造

- `pkgs/` - パッケージ定義
- `lib/` - カスタムNixライブラリ関数（テストファイル付き）
- `modules/` - NixOSモジュール
- `overlays/` - Nixpkgsオーバーレイ
- `_sources/` - nvfetcherによる自動生成ソース情報

## 主要コマンド

- `nix flake check` - テストとチェックの実行
- `nix build .#<package-name>` - パッケージビルド
- `nix fmt` - コードフォーマットとリント
- `nvfetcher` - 上流ソース更新
