{
  lib,
  buildNpmPackage,
  sources,
}:
buildNpmPackage {
  pname = "safe-chain";
  inherit (sources.safe-chain) version src;

  # postPatchはnpm deps FODでも実行されるため、stdenvに含まれるsedのみ使用
  # (nativeBuildInputsのツールはFODでは利用不可)
  postPatch = ''
    # test/e2eワークスペースを除去（node-ptyネイティブモジュールのビルド回避）
    sed -i '/"test\/e2e"/d' package.json
    sed -i 's/"packages\/\*",/"packages\/*"/' package.json
    rm -rf test/e2e
    # ルートdevDependenciesを除去（不要なプリビルドバイナリの混入防止）
    sed -i '/"devDependencies"/,/^  }/d' package.json
    sed -i 's/"AGPL-3.0-or-later",/"AGPL-3.0-or-later"/' package.json
  '';

  npmDepsHash = "sha256-QsFKw5ZWlL0uabDAUlOglxsicBaW79ImK/7iGI6re24=";

  npmWorkspace = "packages/safe-chain";

  # plain JavaScriptでbuildスクリプトが存在しないためスキップ
  dontNpmBuild = true;

  postInstall = ''
    # npmInstallHookはワークスペースファイルを$packageOutに直接コピーするが、
    # node_modules/@aikidosec/safe-chainは../../packages/safe-chainへのシンボリックリンクのまま。
    # $packageOut自体を指すように修正（ワークスペースの内容が$packageOutに展開済みのため）
    local ws_link="$out/lib/node_modules/aikido-safe-chain-workspace/node_modules/@aikidosec/safe-chain"
    if [[ -L "$ws_link" ]]; then
      rm "$ws_link"
      ln -s ../../ "$ws_link"
    fi

    # safe-chain以外の不要なラッパーバイナリを削除
    find $out/bin -type f -name 'aikido-*' -delete
  '';

  meta = {
    description = "Wraps package managers to detect malware before installation";
    homepage = "https://github.com/AikidoSec/safe-chain";
    license = lib.licenses.agpl3Plus;
    maintainers = [ ];
    mainProgram = "safe-chain";
  };
}
