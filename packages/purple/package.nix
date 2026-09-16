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
    rev = "4ee3e763ed6e0e7c1922dba9f58aabe943f404a9";
    hash = "sha256-VEQROrBU0F8MDs4UMRCU0EiujxaVWk2oz35m6l0qb6w=";
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
