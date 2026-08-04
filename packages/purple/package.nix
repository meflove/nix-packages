{
  lib,
  fetchFromGitHub,
  rustPlatform,
  # buildDeps
  pkg-config,
  # deps
  openssl,
}: let
  src = fetchFromGitHub {
    owner = "erickochen";
    repo = "purple";
    rev = "c78993e0d2584a2570f025078aa89bc22240fe8d";
    hash = "sha256-twb+x9HwYTnZKQ7mBrzS8Y0bWuCAujO5x8A5MC1sEiw=";
  };

  cargoToml = lib.importTOML "${src.outPath}/Cargo.toml";

  version = "${cargoToml.package.version}-${lib.substring 0 7 src.rev}";
in
  rustPlatform.buildRustPackage (_finalAttrs: {
    pname = "purple";

    inherit src version;

    strictDeps = true;

    nativeBuildInputs = [pkg-config];
    buildInputs = [openssl];

    cargoLock.lockFile = "${src.outPath}/Cargo.lock";

    doCheck = false;

    meta = {
      description = "An open-source terminal SSH manager and SSH config editor for Linux.";
      homepage = "https://github.com/erickochen/purple";
      license = lib.licenses.mit;
      mainProgram = "purple";
    };
  })
