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
    rev = "51818cfa703ec50532575a0d59dd06b94e2ac167";
    hash = "sha256-Iu35ZhZg46NfYEObojHbGN1EPSLkuiaAHn7OEa4b79A=";
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
