{
  lib,
  stdenv,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm_10,
  nodejs_22,
  makeWrapper,
  sources,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "secretlint";
  inherit (sources.secretlint) version src;

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-H216g8jfO2KUJ1XmFfKO+J+VQI6cnkadKyG/3pC5WRk=";
  };

  nativeBuildInputs = [
    nodejs_22
    pnpm_10
    pnpmConfigHook
    makeWrapper
  ];

  env.CI = "true";

  buildPhase = ''
    runHook preBuild
    pnpm --filter "secretlint..." build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    pnpm install --offline --prod --filter="secretlint..." --ignore-scripts

    mkdir -p $out/lib/secretlint
    cp -r packages $out/lib/secretlint/
    cp -r examples $out/lib/secretlint/
    cp -r publish $out/lib/secretlint/
    cp -r node_modules $out/lib/secretlint/

    makeWrapper ${nodejs_22}/bin/node $out/bin/secretlint \
      --add-flags "$out/lib/secretlint/packages/secretlint/bin/secretlint.js"

    runHook postInstall
  '';

  meta = {
    description = "Pluggable linting tool to prevent committing credential";
    homepage = "https://github.com/secretlint/secretlint";
    license = lib.licenses.mit;
    mainProgram = "secretlint";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
