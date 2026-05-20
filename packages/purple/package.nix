{
  lib,
  inputs,
  rustPlatform,
  rev ? inputs.purple.shortRev or inputs.purple.dirtyShortRev or "dirty",
  # buildDeps
  pkg-config,
  # deps
  openssl,
}: let
  inherit (inputs) purple;
  cargoToml = lib.importTOML "${purple.outPath}/Cargo.toml";
in
  rustPlatform.buildRustPackage (_finalAttrs: {
    pname = "purple";
    version = "${cargoToml.package.version}-${rev}";

    src = lib.cleanSource purple;

    strictDeps = true;

    nativeBuildInputs = [pkg-config];
    buildInputs = [openssl];

    cargoLock.lockFile = "${purple.outPath}/Cargo.lock";

    doCheck = false;

    meta = {
      description = "An open-source terminal SSH manager and SSH config editor for Linux.";
      homepage = "https://github.com/erickochen/purple";
      license = lib.licenses.mit;
      mainProgram = "purple";
    };
  })
