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
    rev = "7b23daf476f39c5f52aeb6a5a360d39be99f91a7";
    hash = "sha256-iH2R1f755i+e6eg+dqNJ/9ygaDe5PYISOUD4JyvDO0Y=";
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
