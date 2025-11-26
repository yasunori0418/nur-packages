{
  lib,
  stdenv,
  cmake,
  perl,
  sources,
}:
stdenv.mkDerivation {
  inherit (sources.pict) pname version src;

  nativeBuildInputs = [
    cmake
    perl
  ];

  cmakeFlags = [ "-DCMAKE_BUILD_TYPE=Release" ];

  doCheck = true;

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
