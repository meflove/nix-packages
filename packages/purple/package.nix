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
    rev = "082570db63f18658e3b5868d1e8f398683533d1a";
    hash = "sha256-E3hHt0cvGcC8iQbF54xgLUZUv/hJKsj+Agn8rw4vVvo=";
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
