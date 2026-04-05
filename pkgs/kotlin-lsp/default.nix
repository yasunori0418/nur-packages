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
  version = "262.2310.0";

  selectSystem = attrs: attrs.${system} or (throw "kotlin-lsp: unsupported platform ${system}");

  platform = selectSystem {
    aarch64-darwin = "mac-aarch64";
    x86_64-darwin = "mac-x64";
    aarch64-linux = "linux-aarch64";
    x86_64-linux = "linux-x64";
  };
in
mkDerivation {
  pname = "kotlin-lsp";
  inherit version;

  src = fetchzip {
    url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-${platform}.zip";
    stripRoot = false;
    hash = selectSystem {
      aarch64-darwin = "sha256-d9jImEUN4Np6PY7uczB5hIE89bq9O+hV+Ww1F8WLe68=";
      x86_64-darwin = "sha256-VoDpfxzLBCvZcJlHmC0yp174s4Urc+cEGw0YA4ctRdE=";
      aarch64-linux = "sha256-uyTVY4TX6YCv3/qow+CQeTRpez3PLegDX3OscpKPCUM=";
      x86_64-linux = "sha256-Bf2qkFpNhQC/Mz563OapmCXeKN+dTrYyQbOcF6z6b48=";
    };
  };

  nativeBuildInputs = lib.optionals isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals isLinux [
    zlib
    stdenv.cc.cc.lib
  ];

  # LSPサーバーにGUI/音声関連ライブラリは不要
  autoPatchelfIgnoreMissingDeps = [
    "libX11.so.6"
    "libXext.so.6"
    "libXi.so.6"
    "libXrender.so.1"
    "libXtst.so.6"
    "libasound.so.2"
    "libfreetype.so.6"
    "libwayland-client.so.0"
    "libwayland-cursor.so.0"
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/kotlin-lsp $out/bin
    cp -r . $out/lib/kotlin-lsp/

    chmod +x $out/lib/kotlin-lsp/kotlin-lsp.sh
    find $out/lib/kotlin-lsp/jre -type f -name "*.sh" -exec chmod +x {} +
    find $out/lib/kotlin-lsp/jre -type f -path "*/bin/*" -exec chmod +x {} +

    sed -i 's/chmod +x "$LOCAL_JRE_PATH\/bin\/java"/# permissions set at install time/' \
      $out/lib/kotlin-lsp/kotlin-lsp.sh

    ln -s $out/lib/kotlin-lsp/kotlin-lsp.sh $out/bin/kotlin-lsp

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
