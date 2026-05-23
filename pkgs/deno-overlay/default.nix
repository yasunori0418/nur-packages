{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  unzip,
  libgcc,
  sources,
}:
let
  deno-overlay-src = sources.deno-overlay.src;
  denoSources = lib.importJSON "${deno-overlay-src}/sources.json";
  system = stdenv.hostPlatform.system;

  allVersions = lib.unique (map (entry: entry.version) denoSources.deno);
  latestVersion = lib.foldl' (
    acc: v: if lib.versionOlder acc v then v else acc
  ) (builtins.head allVersions) allVersions;

  matchingEntries = lib.filter (
    entry: entry.version == latestVersion && entry.arch == system
  ) denoSources.deno;

  source = if matchingEntries == [ ] then null else builtins.head matchingEntries;

  mkBinaryInstall = import "${deno-overlay-src}/nix/mkBinaryInstall.nix" {
    inherit
      lib
      stdenv
      fetchurl
      autoPatchelfHook
      unzip
      libgcc
      ;
  };
in
# x86_64-darwin のようにsources.jsonにエントリがない場合は null を返し
# lib.isDerivation フィルタで packages 出力から除外される
if source == null then
  null
else
  mkBinaryInstall {
    inherit (source) version;
    inherit (source) url;
    inherit (source) arch;
    inherit (source) sha256;
  }
