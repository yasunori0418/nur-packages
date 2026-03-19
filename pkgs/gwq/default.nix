{
  lib,
  buildGoModule,
  go_1_26,
  sources,
}:
(buildGoModule.override { go = go_1_26; }) {
  inherit (sources.gwq) pname version src;

  vendorHash = "sha256-4K01Xf1EXl/NVX1loQ76l1bW8QglBAQdvlZSo7J4NPI=";

  # Tests may require external tools, disable for now
  doCheck = false;

  meta = {
    description = "Git worktree manager with fuzzy finder - Work on multiple branches simultaneously";
    homepage = "https://github.com/d-kuro/gwq";
    license = lib.licenses.asl20;
    maintainers = [ ];
    mainProgram = "gwq";
  };
}
