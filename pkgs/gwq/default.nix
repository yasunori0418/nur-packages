{
  lib,
  buildGoModule,
  sources,
}:
buildGoModule {
  inherit (sources.gwq) pname version src;

  vendorHash = "sha256-c1vq9yETUYfY2BoXSEmRZj/Ceetu0NkIoVCM3wYy5iY=";

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
