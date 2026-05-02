{
  sources,
  lib,
  buildGoModule,
}:

buildGoModule rec {
  inherit (sources.roots) pname src version;

  vendorHash = "sha256-uxcT5VzlTCxxnx09p13mot0wVbbas/otoHdg7QSDt4E=";

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/k1LoW/roots.version=${version}"
    "-X github.com/k1LoW/roots.commit=unknown"
    "-X github.com/k1LoW/roots.date=unknown"
    "-X github.com/k1LoW/roots/version.version=${version}"
  ];

  meta = with lib; {
    description = ''
      `roots` is a tool for exploring multiple root directories, such as those in a monorepo project.
    '';
    homepage = "https://github.com/k1LoW/roots";
    changelog = "https://github.com/k1LoW/roots/releases/tag/${version}";
    license = licenses.mit;
    mainProgram = "roots";
  };
}
