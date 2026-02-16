{
  lib,
  buildGoModule,
  sources,
  git,
}:
buildGoModule {
  inherit (sources.cchook) pname version src;

  vendorHash = "sha256-CVd5RqiJPqri2USh+yYsVb1yp0MFdx1rtnKI+/d/YuY=";

  nativeCheckInputs = [ git ];

  doCheck = false;

  meta = {
    description = "A CLI tool that simplifies Claude Code's hook system with YAML syntax and template-based data access";
    homepage = "https://github.com/syou6162/cchook";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
