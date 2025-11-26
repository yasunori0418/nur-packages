{
  lib,
  stdenv,
  cmake,
  sources,
}:
stdenv.mkDerivation {
  inherit (sources.pict) pname version src;

  nativeBuildInputs = [ cmake ];

  cmakeFlags = [ "-DCMAKE_BUILD_TYPE=Release" ];

  # Tests require Perl and may have platform-specific issues
  doCheck = false;

  installPhase = ''
    mkdir -p $out/bin
    cp cli/pict $out/bin/
  '';

  meta = with lib; {
    description = "Pairwise Independent Combinatorial Testing - generates minimal test cases";
    homepage = "https://github.com/microsoft/pict";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
