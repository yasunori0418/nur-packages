{
  lib,
  stdenvNoCC,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  zlib,
}:
let
  inherit (stdenvNoCC) mkDerivation;
  inherit (stdenvNoCC.hostPlatform) system isLinux;
  version = "262.9593.0";

  selectSystem = attrs: attrs.${system} or (throw "kotlin-lsp: unsupported platform ${system}");

  # v262.4739.0 以降、配布物の命名と形式が変更された
  # macOS は .sit (実体は ZIP)、Linux は .tar.gz
  archiveInfo = selectSystem {
    aarch64-darwin = {
      suffix = "-aarch64";
      ext = "sit";
      extension = "zip";
    };
    x86_64-darwin = {
      suffix = "";
      ext = "sit";
      extension = "zip";
    };
    aarch64-linux = {
      suffix = "-aarch64";
      ext = "tar.gz";
      extension = null;
    };
    x86_64-linux = {
      suffix = "";
      ext = "tar.gz";
      extension = null;
    };
  };
in
mkDerivation {
  pname = "kotlin-lsp";
  inherit version;

  src = fetchzip (
    {
      # v262.8190.0 以降、配布物の置き場が /kotlin-lsp/ から /language-server/kotlin-server/ へ移動した
      url = "https://download-cdn.jetbrains.com/language-server/kotlin-server/${version}/kotlin-server-${version}${archiveInfo.suffix}.${archiveInfo.ext}";
      hash = selectSystem {
        aarch64-darwin = "sha256-qDS5nfZtxAaZUGlaxbcdP8nC1vxYYg1ynj+kwSwo37Q=";
        x86_64-darwin = "sha256-amsA9QP+xgpLitwpG7M3Ej0tVRgXZv3Sz1w6Tk/K2CQ=";
        aarch64-linux = "sha256-769vjedw4TzXPak1U/ls69sIiyow3057VGAADBCXtsU=";
        x86_64-linux = "sha256-6ajvuyFga+IL9eLqNKCPphdVwRxpFQSQOy54HGreEqw=";
      };
    }
    // lib.optionalAttrs (archiveInfo.extension != null) {
      inherit (archiveInfo) extension;
    }
  );

  nativeBuildInputs = lib.optionals isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals isLinux [
    zlib
    stdenv.cc.cc.lib
  ];

  # LSPサーバーにGUI/音声関連ライブラリは不要
  # libc.musl-x86_64.so.1: libgcompat-ext.soはmusl互換レイヤーでglibc環境には不要
  # libxkbcommon.so.0: Wayland GUI用でLSPサーバーには不要
  autoPatchelfIgnoreMissingDeps = [
    "libc.musl-aarch64.so.1"
    "libc.musl-x86_64.so.1"
    "libX11.so.6"
    "libXext.so.6"
    "libXi.so.6"
    "libXrender.so.1"
    "libXtst.so.6"
    "libasound.so.2"
    "libfreetype.so.6"
    "libwayland-client.so.0"
    "libwayland-cursor.so.0"
    "libxkbcommon.so.0"
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/kotlin-lsp $out/bin
    cp -r . $out/lib/kotlin-lsp/

    chmod +x $out/lib/kotlin-lsp/kotlin-lsp.sh
    chmod +x $out/lib/kotlin-lsp/bin/intellij-server
    find $out/lib/kotlin-lsp/jbr -type f -path "*/bin/*" -exec chmod +x {} +

    ln -s $out/lib/kotlin-lsp/bin/intellij-server $out/bin/kotlin-lsp

    runHook postInstall
  '';

  meta = {
    description = "Kotlin Language Server by JetBrains";
    homepage = "https://github.com/Kotlin/kotlin-lsp";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
    mainProgram = "kotlin-lsp";
  };
}
