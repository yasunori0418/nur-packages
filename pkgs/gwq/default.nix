{
  lib,
  buildGoModule,
  sources,
}:
buildGoModule {
  inherit (sources.gwq) pname version src;

  vendorHash = "sha256-gUtRhIwwccCIXfG11F6bl/hhy1Dtdpkwzcenk985LAU=";

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
