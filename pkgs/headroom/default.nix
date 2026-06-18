{
  lib,
  stdenv,
  sources,
  python3,
  fetchFromGitHub,
  rustPlatform,
  cargo,
  rustc,
  cmake,
  perl,
  onnxruntime,
  ast-grep,
}:
let
  python = python3.override {
    packageOverrides =
      self: super:
      {
        # nixpkgs の litellm は 1.86.0 だが headroom は >=1.86.2 を要求する。
        # 上流フロアを厳守するため src ごと 1.86.2 に引き上げる。
        # (1.86.0→1.86.2 で [project] dependencies は不変、nixpkgs 側は doCheck=false
        #  かつ postPatch の uv_build ピンも 1.86.2 で一致するため安全に差し替え可能)
        litellm = super.litellm.overridePythonAttrs (_: rec {
          version = "1.86.2";
          src = fetchFromGitHub {
            owner = "BerriAI";
            repo = "litellm";
            tag = "v${version}";
            hash = "sha256-ykF2mueHLfaMmT0iGCLxGcHR5QASh6itcihbrbU+pTk=";
          };
        });
      }
      # sentence-transformers は darwin のバイナリキャッシュに無く(ソースビルドになる)、
      # その nativeCheckInputs が transformers[audio] → phonemizer → dlinfo を含む。
      # dlinfo は darwin で実際にテストが失敗して `broken` 指定されており、phonemizer ごと
      # darwin ではビルド不能。テスト用の入力に過ぎないため、sentence-transformers の
      # チェックを無効化して phonemizer 連鎖を切り、ソースビルドを通す。
      # この問題は darwin 限定 (linux では dlinfo が壊れず sentence-transformers は
      # キャッシュ済み) なので、linux でキャッシュを外さないよう darwin だけ適用する。
      // lib.optionalAttrs stdenv.hostPlatform.isDarwin {
        sentence-transformers = super.sentence-transformers.overridePythonAttrs (_: {
          doCheck = false;
          nativeCheckInputs = [ ];
        });
      };
  };
  pp = python.pkgs;
in
# headroom-ai は maturin/PyO3 製。1つの wheel に Python ソース (headroom/) と
# Rust 拡張 (headroom._core, crates/headroom-py の cdylib) を同梱する構成。
# そのため buildPythonPackage + maturinBuildHook + fetchCargoVendor でビルドする。
pp.buildPythonPackage rec {
  pname = "headroom";
  inherit (sources.headroom) version src;
  pyproject = true;

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    name = "${pname}-${version}-cargo-deps";
    hash = "sha256-gd5eh1gL2wJTjKMQN2DSjSGFfDiUzC+jIJVjBYU+mJ8=";
  };

  # crates/headroom-core は fastembed v5 → ort (ONNX Runtime) を
  # ort-download-binaries-* feature で使う。これはビルド時に ONNX Runtime
  # バイナリをネットからダウンロードするため、ネット遮断の Nix サンドボックスで
  # 失敗する。load-dynamic に切り替えてビルド時 DL を回避し、実行時に
  # ORT_DYLIB_PATH(下の makeWrapperArgs) で nixpkgs の onnxruntime を dlopen させる。
  # (magika クレートは ort を default-features=false で使い download-binaries を
  #  有効化しないため、fastembed 側だけ切り替えれば download-binaries は無効になる)
  postPatch = ''
    substituteInPlace crates/headroom-core/Cargo.toml \
      --replace-fail '"ort-download-binaries-rustls-tls",' '"ort-load-dynamic",'
  '';

  # headroom は複数のサブコマンドで自分自身を別プロセスとして起動する
  # (`sys.executable -m headroom.cli proxy` / `-m headroom.memory.sync` /
  #  `-m headroom.proxy.server` / `-m lm_eval` / `-c "import hnswlib"` 等)。
  # しかし Nix の buildPythonPackage ラッパーは依存 site-packages を実行時に
  # sys.path へ注入するだけで PYTHONPATH 環境変数を立てないため、素のインタプリタ
  # (sys.executable) で起動した子プロセスは headroom / 依存パッケージを import できず
  # `ModuleNotFoundError: No module named 'headroom'`(または 'hnswlib' 等) で失敗する。
  # nix-subprocess-pythonpath.patch で以下を行う:
  #   - proxy 起動 (CLI サブコマンド等価) は上流の resolve_headroom_command() /
  #     `shutil.which("headroom")` と同じく PATH 上のラッパーバイナリを優先
  #   - モジュール起動 (memory.sync / memory.mcp_server / proxy.server / lm_eval /
  #     hnswlib probe) は子プロセスの env に現在の sys.path から導出した PYTHONPATH を
  #     継承させ、素のインタプリタでも import できるようにする
  patches = [ ./patches/nix-subprocess-pythonpath.patch ];

  nativeBuildInputs = [
    cargo
    rustc
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
    rustPlatform.bindgenHook # onig_sys / aws-lc-sys の bindgen 用 (LIBCLANG_PATH)
    cmake # aws-lc-sys のビルド
    perl # aws-lc-sys のアセンブリ生成
  ];

  # cmake は aws-lc-sys のビルドスクリプトから呼ばれるだけ。cmake の configure
  # フックが headroom 本体に対して走らないよう無効化する (CMakeLists.txt は無い)。
  dontUseCmakeConfigure = true;

  # 公式の推奨インストールは `pip install "headroom-ai[all]"`(全部入り)。
  # [all] = proxy,code,ml,memory,relevance,image,reports,otel,evals,voice,html,
  # benchmark,mcp。これらの extra 依存をすべて含めて proxy 等の機能も使えるようにする。
  # ([all] に含まれない anyllm/agno/strands/memory-stack/bedrock/langchain は対象外)
  dependencies =
    with pp;
    [
      # コア (常に必要)
      tiktoken
      pydantic
      litellm
      click
      rich
      opentelemetry-api
    ]
    ++ [
      # [proxy]
      fastapi
      uvicorn
      httpx
      h2 # httpx[http2] の HTTP/2 トランスポート
      openai
      mcp
      magika
      zstandard
      websockets
      onnxruntime
      transformers
      watchdog
      sqlite-vec
      # [code]
      tree-sitter-language-pack
      # [ml] / [voice]
      torch
      huggingface-hub
      # [memory]
      hnswlib
      sentence-transformers
      # [relevance]
      fastembed
      numpy
      # [image] (py>=3.13 では rapidocr-onnxruntime ではなく rapidocr + onnxruntime)
      pillow
      sentencepiece
      rapidocr
      # [reports]
      jinja2
      # [otel]
      opentelemetry-sdk
      opentelemetry-exporter-otlp-proto-http
      # [evals]
      datasets
      scikit-learn
      anthropic
      # [html]
      trafilatura
      # [benchmark]
      lm-eval
    ];

  # ast-grep-cli は nixpkgs に Python パッケージとして存在しない。実体は ast-grep/sg
  # バイナリを提供する wheel なので、依存指定を外し ast-grep バイナリを PATH に注入する。
  pythonRemoveDeps = [ "ast-grep-cli" ];

  makeWrapperArgs = [
    "--set ORT_DYLIB_PATH ${onnxruntime}/lib/libonnxruntime${stdenv.hostPlatform.extensions.sharedLibrary}"
    "--prefix PATH : ${lib.makeBinPath [ ast-grep ]}"
  ];

  pythonImportsCheck = [
    "headroom"
    "headroom._core"
  ];

  # テストは外部 LLM API / モデルダウンロードを必要とするものが多いため無効化。
  doCheck = false;

  meta = {
    description = "The Context Optimization Layer for LLM Applications - Cut costs by 50-90%";
    homepage = "https://github.com/chopratejas/headroom";
    changelog = "https://github.com/chopratejas/headroom/blob/main/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = [ ];
    mainProgram = "headroom";
  };
}
