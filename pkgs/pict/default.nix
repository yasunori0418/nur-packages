{
  lib,
  stdenv,
  cmake,
  perl,
  sources,
}:
stdenv.mkDerivation {
  inherit (sources.pict) pname version src;

  # patches = [
  #   # Fix Unicode/Japanese text handling on macOS
  #   # https://github.com/ishikawa096/pict-fix/commit/ff738a7a3cea75b9a7994369dcb00201703b7216
  #   ./patches/fix-unicode-japanese-text-handling-macos.patch
  # ];

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
