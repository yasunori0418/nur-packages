{
  lib,
  buildGoModule,
  sources,
}:
buildGoModule {
  inherit (sources.laminate) pname version src;

  vendorHash = "sha256-7MdDUbtHHD7TChIc2DrgvYPFGO306zmuRRFmfI3g8vM=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/Songmu/laminate/version.Version=${sources.laminate.version}"
  ];

  # Tests may require external tools, disable for now
  doCheck = false;

  meta = {
    description = "A command-line bridge tool that orchestrates external image generation commands to convert text/code strings to images";
    homepage = "https://github.com/Songmu/laminate";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "laminate";
  };
}
