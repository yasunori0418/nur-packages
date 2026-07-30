{
  lib,
  rustPlatform,
  sources,
  git,
}:
rustPlatform.buildRustPackage {
  inherit (sources.sara) pname version src;

  # Cargo.lock は上流リポジトリに含まれるため、fetch 済み src から参照する。
  cargoLock.lockFile = "${sources.sara.src}/Cargo.lock";

  nativeCheckInputs = [ git ];

  # このテストは作業ディレクトリが Git リポジトリであることを前提とする。
  # nix ビルドは .git を持たないソースコピーから行うため前提が成立しない。
  # 他のテストは自己完結しているのでそのまま実行される。
  checkFlags = [ "--skip=repository::git::tests::test_is_git_repo" ];

  meta = {
    description = "Manage architecture documents and requirements as a knowledge graph";
    homepage = "https://github.com/cledouarec/sara";
    license = lib.licenses.asl20;
    maintainers = [ ];
    mainProgram = "sara";
  };
}
