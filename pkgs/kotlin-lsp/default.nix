{
  lib,
  stdenvNoCC,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  zlib,
}:
let
  inherit (stdenvNoCC) mkDerivation;
  inherit (stdenvNoCC.hostPlatform) system isLinux;
  version = "263.7084.0";

  selectSystem = attrs: attrs.${system} or (throw "kotlin-lsp: unsupported platform ${system}");

  # v262.4739.0 以降、配布物の命名と形式が変更された
  # macOS は .sit (実体は ZIP)、Linux は .tar.gz
  archiveInfo = selectSystem {
    aarch64-darwin = {
      suffix = "-aarch64";
      ext = "sit";
    };
    x86_64-darwin = {
      suffix = "";
      ext = "sit";
    };
    aarch64-linux = {
      suffix = "-aarch64";
      ext = "tar.gz";
    };
    x86_64-linux = {
      suffix = "";
      ext = "tar.gz";
    };
  };
in
mkDerivation {
  pname = "kotlin-lsp";
  inherit version;

  # 上流が配布物ごとに公開している <配布物>.sha256 と同じ値を使えるよう、
  # 展開後の NAR ハッシュになる fetchzip ではなく fetchurl でアーカイブを取得する
  src = fetchurl {
    # v262.8190.0 以降、配布物の置き場が /kotlin-lsp/ から /language-server/kotlin-server/ へ移動した
    # download-cdn への直リンクは署名なしだと 404 になる (2026-10 時点) ため、署名付き URL へリダイレクトする download.jetbrains.com を使う
    url = "https://download.jetbrains.com/language-server/kotlin-server/${version}/kotlin-server-${version}${archiveInfo.suffix}.${archiveInfo.ext}";
    hash = selectSystem {
      aarch64-darwin = "sha256-tAO/ilS9RY47pnMc+KuzNAvgi0OcA1dt/AKxP682lLg=";
      x86_64-darwin = "sha256-spw5Ol5UEVPQPWJueUYmhDfjWKZnpfkUoSbbtAB2ZLE=";
      aarch64-linux = "sha256-RQq3wdgOSBBqpCm0jLQibYLKEqiiQARHrgI4Z5R4DKw=";
      x86_64-linux = "sha256-rgxLAeF6tzpKUienjqmebcvj5JlgAxWyJ1mk5M3dEd8=";
    };
  };

  nativeBuildInputs =
    lib.optionals isLinux [
      autoPatchelfHook
    ]
    ++ lib.optionals (archiveInfo.ext == "sit") [
      unzip
    ];

  # .sit は拡張子から展開方法を判別できないため、実体の ZIP として明示的に展開する
  unpackCmd = lib.optionalString (archiveInfo.ext == "sit") "unzip -qq $curSrc";

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

  # 配布バイナリを展開するだけなので cachix へ push せず手元で fetch する
  preferLocalBuild = true;

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
