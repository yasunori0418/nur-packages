{
  lib,
  rustPlatform,
  pkg-config,
  dbus,
  apple-sdk_14,
  darwinMinVersionHook,
  sources,
  stdenv,
}:
rustPlatform.buildRustPackage {
  inherit (sources.gws) pname version src;

  cargoHash = "sha256-ah/aYp/dAymh6g/Kw9Scmarvrg/Zli1Drtvlnq6gDp8=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs =
    lib.optionals stdenv.hostPlatform.isLinux [
      dbus
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      apple-sdk_14
      (darwinMinVersionHook "10.15")
    ];

  doCheck = false;

  meta = {
    description = "Google Workspace CLI — one command-line tool for Drive, Gmail, Calendar, Sheets, Docs, Chat, Admin, and more";
    homepage = "https://github.com/googleworkspace/cli";
    license = lib.licenses.asl20;
    maintainers = [ ];
    mainProgram = "gws";
  };
}
