{
  lib,
  buildGoModule,
  sources,
}:
buildGoModule {
  inherit (sources.k1Low-deck) pname version src;

  vendorHash = "sha256-xCIlcbycD9Wz4Wvpleigdw/W2n7x9pzWD32TSngx5fY=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/k1LoW/deck/version.Version=${sources.k1Low-deck.version}"
  ];

  # Tests fail due to vendoring issues in testdata
  doCheck = false;

  meta = {
    description = "deck is a tool for creating deck using Markdown and Google Slides";
    homepage = "https://github.com/k1LoW/deck";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "deck";
  };
}
