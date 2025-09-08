{
  lib,
  buildGoModule,
  sources,
  git,
}:
buildGoModule {
  inherit (sources.cchook) pname version src;

  vendorHash = "sha256-2RGMSBWbdaDOfnu31GhRuFj6JUiGvmW6n1LxfLOFJew=";

  nativeCheckInputs = [ git ];

  doCheck = false;

  meta = {
    description = "A CLI tool that simplifies Claude Code's hook system with YAML syntax and template-based data access";
    homepage = "https://github.com/syou6162/cchook";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
