# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

個人用NUR（Nix User Repository）でカスタムNixパッケージ、ライブラリ関数、NixOSモジュール、オーバーレイを含む。Nix flakesを使用し、複数システム（aarch64-darwin, aarch64-linux, x86_64-darwin, x86_64-linux）をサポート。

## 開発コマンド

### ビルドとテスト

- `nix flake check` - 全テストとチェックを実行（フォーマット、ユニットテスト）
- `nix build .#<package-name>` - 特定パッケージをビルド（例：`nix build .#neovim`）
- `nix develop` - 開発シェルに入る（nvfetcher, cachix, node2nix, nix-unitが利用可能）

### ソース管理

- `nvfetcher` - nvfetcher.tomlで定義された上流ソースを更新
- `node2nix -l node-packages.json -c node-packages.nix -o node-env.nix` - Node.jsパッケージを更新（pkgs/node2nixディレクトリから実行）

### コードフォーマット

- `nix fmt` - nixfmt-rfc-styleでNixコードをフォーマットし、statixでリント実行

## アーキテクチャ

### ディレクトリ構造

- `pkgs/` - カスタムビルド用のパッケージ定義（neovim, vim, node2nixパッケージ）
- `lib/` - カスタムNixライブラリ関数（対応するテストファイル付き）
- `modules/` - NixOSモジュール
- `overlays/` - Nixpkgsオーバーレイ
- `_sources/` - nvfetcherによる自動生成されたソース情報

### 主要ファイル

- `default.nix` - lib、modules、overlays、packagesのメインパッケージセットエクスポート
- `flake.nix` - packages、devShells、checks、formatterの出力を持つフレーク定義
- `nvfetcher.toml` - 上流パッケージのソース定義（neovim, vim）
- `treefmt.nix` - フォーマット設定（nixfmt, statix, prettier）
- `ci.nix` - ビルド可能およびキャッシュ可能パッケージのCI専用フィルタリング

### パッケージ管理

- nvfetcherを使用して上流ソースを追跡・更新
- Node.jsパッケージはnode2nixで管理
- カスタムvim/neovimビルドは開発ソースで上流バージョンをオーバーライド
- 全パッケージはforAllSystemsヘルパーでマルチシステムビルドをサポート

### テスト戦略

- nix-unitフレームワークを使用したライブラリ関数のユニットテスト
- `nix flake check`による統合テスト
- CIは非破損かつ自由なパッケージを全てビルドし、cachixでキャッシュ
